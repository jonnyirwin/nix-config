#!/usr/bin/env bash

# Floating break window for Pomodoro timer using native tools
# Usage: pomodoro-break-window.sh <break_type> <duration_minutes>

BREAK_TYPE="$1"
DURATION_MINUTES="$2"
CONFIG_FILE="${POMODORO_CONF:?POMODORO_CONF must be set by the Nix wrapper}"

# Load configuration
if [ -f "$CONFIG_FILE" ]; then
    source "$CONFIG_FILE"
else
    FLOATING_WINDOW_SIZE="400x300"
    FLOATING_WINDOW_POSITION="center"
    BREAK_ICON="☕"
fi

# Break messages
case "$BREAK_TYPE" in
    "SHORT_BREAK")
        TITLE="☕ Short Break Time!"
        MESSAGE="Time for a ${DURATION_MINUTES}-minute break!\n\n• Stretch your body\n• Rest your eyes\n• Take deep breaths\n• Hydrate"
        ICON="☕"
        ;;
    "LONG_BREAK")
        TITLE="🌟 Long Break Time!"
        MESSAGE="Time for a ${DURATION_MINUTES}-minute break!\n\n• Take a walk\n• Have a snack\n• Chat with someone\n• Do something you enjoy"
        ICON="🌟"
        ;;
    *)
        TITLE="☕ Break Time!"
        MESSAGE="Time for a ${DURATION_MINUTES}-minute break!\n\nTake care of yourself!"
        ICON="☕"
        ;;
esac

# Calculate remaining time in seconds
REMAINING_SECONDS=$((DURATION_MINUTES * 60))

# Create a lock file to prevent multiple instances
LOCK_FILE="${XDG_STATE_HOME:-$HOME/.local/state}/pomodoro/break-window.lock"
mkdir -p "$(dirname "$LOCK_FILE")"
if [ -f "$LOCK_FILE" ]; then
    echo "Break window already running, exiting..."
    exit 1
fi
echo $$ > "$LOCK_FILE"

# Cleanup function
cleanup() {
    rm -f "$LOCK_FILE"
    rm -f "${XDG_STATE_HOME:-$HOME/.local/state}/pomodoro/break-cancel"
    exit
}

# Set trap to cleanup on exit
trap cleanup EXIT INT TERM

# Create a floating terminal window with countdown
create_floating_break() {
    local temp_script="${XDG_STATE_HOME:-$HOME/.local/state}/pomodoro/break-display.sh"
    
    cat > "$temp_script" << 'EOF'
#!/usr/bin/env bash

REMAINING=$1
TITLE="$2"
MESSAGE="$3"
ICON="$4"

# Function to format time
format_time() {
    local total_seconds=$1
    local minutes=$((total_seconds / 60))
    local seconds=$((total_seconds % 60))
    printf "%02d:%02d" $minutes $seconds
}

# Clear screen and hide cursor
clear
echo -e "\033[?25l"

# Set terminal title
echo -e "\033]0;$TITLE\007"

while true; do
    clear
    
    # Get the actual remaining time from the main timer
    TIMER_STATE=$(pomodoro display 2>/dev/null)
    if echo "$TIMER_STATE" | grep -q "SHORT_BREAK\|LONG_BREAK"; then
        # Extract the actual remaining time from the main timer
        ACTUAL_TIME=$(echo "$TIMER_STATE" | grep -o '[0-9][0-9]:[0-9][0-9]' | head -1)
        if [ -n "$ACTUAL_TIME" ]; then
            # Convert MM:SS to total seconds
            MINUTES=$(echo "$ACTUAL_TIME" | cut -d: -f1)
            SECONDS=$(echo "$ACTUAL_TIME" | cut -d: -f2)
            REMAINING=$(( (10#$MINUTES * 60) + 10#$SECONDS ))
        fi
    fi
    
    # Only exit if timer is no longer in break mode (not just when time reaches 0)
    if ! echo "$TIMER_STATE" | grep -q "SHORT_BREAK\|LONG_BREAK"; then
        break
    fi
    
    # Allow REMAINING to stay at 0 if we're still in break mode
    if [ $REMAINING -lt 0 ]; then
        REMAINING=0
    fi
    
    # Center the content
    echo ""
    echo ""
    echo "    ╔══════════════════════════════════════════════════════╗"
    echo "    ║                                                      ║"
    echo "    ║               $ICON BREAK TIME! $ICON               ║"
    echo "    ║                                                      ║"
    echo "    ║                    $(format_time $REMAINING)                    ║"
    echo "    ║                                                      ║"
    echo "    ║  • Stretch your body                                 ║"
    echo "    ║  • Rest your eyes                                    ║"
    echo "    ║  • Take deep breaths                                 ║"
    echo "    ║  • Hydrate yourself                                  ║"
    echo "    ║                                                      ║"
    echo "    ║          Press 'q' to skip to work                   ║"
    echo "    ║          Press 's' to stop completely               ║"
    echo "    ║          Press '+' to add 5 minutes                  ║"
    echo "    ║                                                      ║"
    echo "    ╚══════════════════════════════════════════════════════╝"
    echo ""
    echo "                        Take your time!"
    
    # Check for user input (non-blocking)
    read -t 1 -n 1 input
    case "$input" in
        'q'|'Q')
            # Skip break and start work session - communicate back to main timer
            pomodoro skip-break
            break
            ;;
        's'|'S')
            # Stop completely - communicate back to main timer
            pomodoro stop
            break
            ;;
        '+'|'=')
            # Extend break - communicate back to main timer
            pomodoro extend-break
            # Don't modify REMAINING here - let it sync from main timer
            ;;
    esac
    
    # Don't decrement REMAINING here - it will be updated from main timer
done

# Show cursor and clear
echo -e "\033[?25h"
clear
echo "Break finished! Time to get back to work! 🍅"

# Notify main timer that break is finished
pomodoro finish-break

sleep 2

# Clean up
rm -f "$0"
EOF

    chmod +x "$temp_script"
    
    # Launch in a floating terminal window
    kitty --title="$TITLE" --override font_size=14 --override window_padding_width=20 \
          bash "$temp_script" "$REMAINING_SECONDS" "$TITLE" "$MESSAGE" "$ICON" &
    
    # Get the window ID and make it floating
    sleep 0.5
    swaymsg '[title="'$TITLE'"] floating enable'
    swaymsg '[title="'$TITLE'"] resize set 500 400'
    swaymsg '[title="'$TITLE'"] move position center'
    swaymsg '[title="'$TITLE'"] focus'
}

# Use zenity if available (simpler option)
if command -v zenity >/dev/null 2>&1; then
    # Create a cancellation flag file
    CANCEL_FLAG="${XDG_STATE_HOME:-$HOME/.local/state}/pomodoro/break-cancel"
    rm -f "$CANCEL_FLAG"
    
    # Simple zenity dialog with countdown that syncs with main timer
    (
        i=$REMAINING_SECONDS
        while true; do
            # Check for cancellation
            if [ -f "$CANCEL_FLAG" ]; then
                break
            fi
            
            # Get actual remaining time from main timer
            TIMER_STATE=$(pomodoro display 2>/dev/null)
            if echo "$TIMER_STATE" | grep -q "SHORT_BREAK\|LONG_BREAK"; then
                ACTUAL_TIME=$(echo "$TIMER_STATE" | grep -o '[0-9][0-9]:[0-9][0-9]' | head -1)
                if [ -n "$ACTUAL_TIME" ]; then
                    MINUTES=$(echo "$ACTUAL_TIME" | cut -d: -f1)
                    SECONDS=$(echo "$ACTUAL_TIME" | cut -d: -f2)
                    ACTUAL_REMAINING=$(( (10#$MINUTES * 60) + 10#$SECONDS ))
                    
                    # Update progress based on actual remaining time
                    # Stay at 99% when time reaches 0 to prevent premature closing
                    if [ $ACTUAL_REMAINING -le 0 ]; then
                        PROGRESS=99  # Stay at 99% until timer mode actually changes
                        echo $PROGRESS
                        echo "# $TITLE - 00:00 remaining"
                    else
                        PROGRESS=$((100 - (ACTUAL_REMAINING * 100 / REMAINING_SECONDS)))
                        echo $PROGRESS
                        echo "# $TITLE - $ACTUAL_TIME remaining"
                    fi
                else
                    # Fallback if parsing fails
                    echo $((100 - (i * 100 / REMAINING_SECONDS)))
                    echo "# $TITLE - $(printf "%02d:%02d" $((i/60)) $((i%60))) remaining"
                fi
            else
                # Timer is no longer in break mode - exit the loop
                break
            fi
            sleep 1
            ((i--))
        done
        # Don't output 100% automatically - let the monitor process handle closing
    ) | zenity --progress --title="$TITLE" --text="$MESSAGE\n\nCancel = Skip to work session" --width=400 --height=200 &
    
    ZENITY_PID=$!
    
    # Make zenity window floating
    sleep 0.5
    swaymsg '[app_id="zenity"] floating enable'
    swaymsg '[app_id="zenity"] move position center'
    
    # Monitor for zenity cancellation
    (
        while kill -0 $ZENITY_PID 2>/dev/null; do
            sleep 0.5
        done
        # Zenity process ended - check exit code
        wait $ZENITY_PID 2>/dev/null
        ZENITY_EXIT_CODE=$?
        
        if [ $ZENITY_EXIT_CODE -eq 1 ]; then
            # User cancelled - signal cancellation and skip break
            touch "$CANCEL_FLAG"
            pomodoro skip-break
        else
            # Check if we're still in break mode - only call finish-break if we are
            TIMER_STATE=$(pomodoro display 2>/dev/null)
            if echo "$TIMER_STATE" | grep -q "SHORT_BREAK\|LONG_BREAK"; then
                # Still in break mode when zenity closed - this means it finished naturally
                pomodoro finish-break
            fi
            # If not in break mode anymore, something else already transitioned the timer
        fi
        
        # Clean up
        rm -f "$CANCEL_FLAG"
    ) &
    
elif command -v yad >/dev/null 2>&1; then
    # Use yad if available
    yad --title="$TITLE" --text="$MESSAGE\n\nDuration: $DURATION_MINUTES minutes" \
        --button="Skip:1" --button="OK:0" --width=400 --height=200 \
        --timeout=$((DURATION_MINUTES * 60)) --timeout-indicator=top &
    
    sleep 0.5
    swaymsg '[app_id="yad"] floating enable'
    swaymsg '[app_id="yad"] move position center'
    
else
    # Fallback to floating terminal
    create_floating_break
fi
