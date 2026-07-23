#!/usr/bin/env bash

# Pomodoro timer script for Waybar
# Creates a temporary file to store the timer state

TIMER_FILE="${XDG_STATE_HOME:-$HOME/.local/state}/pomodoro/state"
LOCK_FILE="${XDG_STATE_HOME:-$HOME/.local/state}/pomodoro/lock"
CONFIG_FILE="${POMODORO_CONF:?POMODORO_CONF must be set by the Nix wrapper}"

# The Nix wrapper does not create this; the scripts own their state directory.
mkdir -p "$(dirname "$TIMER_FILE")"

# Load configuration
if [ -f "$CONFIG_FILE" ]; then
    source "$CONFIG_FILE"
else
    # Default values if config file doesn't exist
    WORK_TIME_MINUTES=25
    SHORT_BREAK_MINUTES=5
    LONG_BREAK_MINUTES=15
    SESSIONS_BEFORE_LONG_BREAK=4
    ENABLE_NOTIFICATIONS=true
    NOTIFICATION_SOUND=false
    WORK_ICON="󰔛"
    BREAK_ICON="☕"
    PAUSED_ICON="⏸️"
fi

# Convert minutes to seconds
WORK_TIME=$((WORK_TIME_MINUTES * 60))
SHORT_BREAK=$((SHORT_BREAK_MINUTES * 60))
LONG_BREAK=$((LONG_BREAK_MINUTES * 60))

# Initialize timer file if it doesn't exist
if [ ! -f "$TIMER_FILE" ]; then
    echo "IDLE:0:0:0" > "$TIMER_FILE"
fi

# Function to get current state
get_state() {
    if [ -f "$TIMER_FILE" ]; then
        cat "$TIMER_FILE"
    else
        echo "IDLE:0:0:0"
    fi
}

# Function to format time
format_time() {
    local seconds=$1
    local minutes=$((seconds / 60))
    local remaining_seconds=$((seconds % 60))
    printf "%02d:%02d" $minutes $remaining_seconds
}

# Function to create progress bar
create_progress_bar() {
    local current=$1
    local total=$2
    local width=8
    
    if [ $total -eq 0 ]; then
        echo "████████"
        return
    fi
    
    local progress=$((current * width / total))
    local filled=""
    local empty=""
    
    for i in $(seq 1 $progress); do
        filled="${filled}█"
    done
    
    for i in $(seq $((progress + 1)) $width); do
        empty="${empty}░"
    done
    
    echo "$filled$empty"
}

# Function to play a happy break tune
play_break_tune() {
    # Play a simple fantasy-style ascending melody
    (timeout 0.2s speaker-test -t sine -f 440 -l 1 >/dev/null 2>&1; sleep 0.05) &  # A4
    sleep 0.25
    (timeout 0.2s speaker-test -t sine -f 523 -l 1 >/dev/null 2>&1; sleep 0.05) &  # C5
    sleep 0.25
    (timeout 0.2s speaker-test -t sine -f 659 -l 1 >/dev/null 2>&1; sleep 0.05) &  # E5
    sleep 0.25
    (timeout 0.3s speaker-test -t sine -f 880 -l 1 >/dev/null 2>&1) &             # A5
    wait
}

# Function to play a simple work tone
play_work_tone() {
    # Single descending tone for work time
    (timeout 0.2s speaker-test -t sine -f 600 -l 1 >/dev/null 2>&1) || (printf "\a")
}

# Function to start work session
start_work() {
    echo "WORK:$WORK_TIME:$(date +%s):0" > "$TIMER_FILE"
    # Reset completed sessions when starting a new pomodoro cycle
    sed -i 's/COMPLETED_SESSIONS=.*/COMPLETED_SESSIONS=0/' "$CONFIG_FILE"
}

# Function to start short break
start_short_break() {
    echo "SHORT_BREAK:$SHORT_BREAK:$(date +%s):0" > "$TIMER_FILE"
}

# Function to start long break
start_long_break() {
    echo "LONG_BREAK:$LONG_BREAK:$(date +%s):0" > "$TIMER_FILE"
}

# Function to pause/resume timer
toggle_pause() {
    local state=$(get_state)
    IFS=':' read -r mode remaining start_time paused_time <<< "$state"
    
    if [ "$mode" = "IDLE" ]; then
        return
    fi
    
    local current_time=$(date +%s)
    
    if [ "$paused_time" -eq 0 ]; then
        # Currently running, pause it
        local elapsed=$((current_time - start_time))
        local new_remaining=$((remaining - elapsed))
        echo "$mode:$new_remaining:0:$current_time" > "$TIMER_FILE"
    else
        # Currently paused, resume it
        echo "$mode:$remaining:$current_time:0" > "$TIMER_FILE"
    fi
}

# Function to stop timer
stop_timer() {
    echo "IDLE:0:0:0" > "$TIMER_FILE"
}

# Function to get display output
get_display() {
    local state=$(get_state)
    IFS=':' read -r mode remaining start_time paused_time <<< "$state"
    
    case "$mode" in
        "IDLE")
            echo '{"text": "󰔛 Start", "tooltip": "Click to start pomodoro", "class": "idle"}'
            ;;
        "WORK"|"SHORT_BREAK"|"LONG_BREAK")
            local current_time=$(date +%s)
            local time_left
            
            if [ "$paused_time" -eq 0 ]; then
                # Timer is running
                local elapsed=$((current_time - start_time))
                time_left=$((remaining - elapsed))
                
                if [ $time_left -le 0 ]; then
                    # Timer finished
                    
                    if [ "$mode" = "WORK" ]; then
                        # Work session completed - increment counter
                        CURRENT_COMPLETED=$(grep "COMPLETED_SESSIONS=" "$CONFIG_FILE" | cut -d= -f2)
                        NEW_COMPLETED=$((CURRENT_COMPLETED + 1))
                        sed -i "s/COMPLETED_SESSIONS=.*/COMPLETED_SESSIONS=$NEW_COMPLETED/" "$CONFIG_FILE"
                        
                        # Check if it's time for a long break
                        if [ $NEW_COMPLETED -ge $SESSIONS_BEFORE_LONG_BREAK ]; then
                            # Time for long break - reset counter
                            sed -i "s/COMPLETED_SESSIONS=.*/COMPLETED_SESSIONS=0/" "$CONFIG_FILE"
                            echo "LONG_BREAK:$LONG_BREAK:$(date +%s):0" > "$TIMER_FILE"
                            if [ "$ENABLE_NOTIFICATIONS" = "true" ]; then
                                notify-send "Pomodoro" "Time for a long break! ($SESSIONS_BEFORE_LONG_BREAK sessions completed)" -u normal
                                if [ "$NOTIFICATION_SOUND" = "true" ]; then
                                    play_break_tune &
                                fi
                            fi
                        else
                            # Regular short break
                            echo "SHORT_BREAK:$SHORT_BREAK:$(date +%s):0" > "$TIMER_FILE"
                            if [ "$ENABLE_NOTIFICATIONS" = "true" ]; then
                                notify-send "Pomodoro" "Time for a break! ($NEW_COMPLETED/$SESSIONS_BEFORE_LONG_BREAK sessions)" -u normal
                                if [ "$NOTIFICATION_SOUND" = "true" ]; then
                                    play_break_tune &
                                fi
                            fi
                        fi
                    else
                        # Break finished - automatically transition to work
                        echo "WORK:$WORK_TIME:$(date +%s):0" > "$TIMER_FILE"
                        if [ "$ENABLE_NOTIFICATIONS" = "true" ]; then
                            notify-send "Pomodoro" "Break over! Work session started." -u normal
                            if [ "$NOTIFICATION_SOUND" = "true" ]; then
                                play_work_tone &
                            fi
                        fi
                    fi
                    get_display
                    return
                fi
                
                local icon="$WORK_ICON"
                local css_class="running"
                if [ "$mode" != "WORK" ]; then
                    icon="$BREAK_ICON"
                    css_class="break"
                fi
                
                # Show 00:00 if time_left is 0 or negative
                if [ $time_left -le 0 ]; then
                    time_left=0
                fi
                
                # Calculate progress and percentage
                local total_time
                case "$mode" in
                    "WORK") total_time=$WORK_TIME ;;
                    "SHORT_BREAK") total_time=$SHORT_BREAK ;;
                    "LONG_BREAK") total_time=$LONG_BREAK ;;
                esac
                
                local elapsed=$((total_time - time_left))
                local percentage=$((elapsed * 100 / total_time))
                local progress_bar=$(create_progress_bar $elapsed $total_time)
                
                echo "{\"text\": \"$icon $(format_time $time_left) $progress_bar ${percentage}%\", \"tooltip\": \"$mode - $(format_time $time_left) remaining ($percentage% complete)\", \"class\": \"$css_class\"}"
            else
                # Timer is paused
                time_left=$remaining
                
                # Calculate progress and percentage for paused state
                local total_time
                case "$mode" in
                    "WORK") total_time=$WORK_TIME ;;
                    "SHORT_BREAK") total_time=$SHORT_BREAK ;;
                    "LONG_BREAK") total_time=$LONG_BREAK ;;
                esac
                
                local elapsed=$((total_time - time_left))
                local percentage=$((elapsed * 100 / total_time))
                local progress_bar=$(create_progress_bar $elapsed $total_time)
                
                echo "{\"text\": \"$PAUSED_ICON $(format_time $time_left) $progress_bar ${percentage}%\", \"tooltip\": \"$mode - Paused ($percentage% complete)\", \"class\": \"paused\"}"
            fi
            ;;
    esac
}

# Handle command line arguments
case "$1" in
    "start")
        start_work
        ;;
    "short-break")
        start_short_break
        ;;
    "long-break")
        start_long_break
        ;;
    "toggle")
        toggle_pause
        ;;
    "stop")
        stop_timer
        ;;
    "display"|*)
        get_display
        ;;
esac
