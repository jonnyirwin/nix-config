# Neovim Keybindings

This document provides a comprehensive list of keybindings used in this Neovim configuration.

## Key Namespaces

| Prefix          | Purpose                       |
|-----------------|-------------------------------|
| `<leader>f`     | Find (Telescope)              |
| `<leader>g`     | Git                           |
| `<leader>b`     | Buffer                        |
| `<leader>w`     | Window                        |
| `<leader>r`     | Rails/Ruby                    |
| `<leader>d`     | Debug (DAP)                   |
| `<leader>t`     | Test                          |
| `<leader>x`     | Terminal/Trouble              |
| `<leader>a`     | Tabs                          |
| `<leader>i`     | IEx/Elixir Navigation         |
| `<leader>ix`    | IEx/Elixir Terminal Commands  |
| `<leader>u`     | UI Toggles                    |
| `<leader>e`     | File Explorer (Oil)           |
| `<leader>l`     | LSP                           |
| `<leader>v`     | Vimux                         |
| `<leader>m`     | Motion/Harpoon                |
| `<leader>n`     | Next (Treesitter swapping)   |
| `<leader>p`     | Previous (Treesitter swapping) |
| `<leader>s`     | Sort/Substitute               |

## File Navigation

- `<leader>e` - Open Oil file explorer (float)
- `-` - Open parent directory in Oil

## Window Management

- `<leader>wv` - Split window vertically
- `<leader>wh` - Split window horizontally
- `<leader>we` - Make splits equal size
- `<leader>wx` - Close current split
- `<C-h/j/k/l>` - Navigate between windows/tmux panes

## Tab Management

- `<leader>ao` - Open new tab
- `<leader>ax` - Close current tab
- `<leader>an` - Go to next tab
- `<leader>ap` - Go to previous tab

## Find with Telescope

- `<leader>ff` - Find files (including hidden)
- `<leader>fi` - Find files (including ignored)
- `<leader>fg` - Find text (grep, including hidden)
- `<leader>fb` - Find buffers
- `<leader>fh` - Find help
- `<leader>fa` - Find all files (ignore gitignore)
- `<leader>fd` - Find files in current directory
- `<leader>fe` - Find diagnostics (all workspace)
- `<leader>fE` - Find diagnostics (current buffer only)
- `<leader>fs` - Find LSP document symbols
- `<leader>fS` - Find LSP workspace symbols

## Git

- `<leader>gg` - Git status (fugitive)
- `<leader>gl` - LazyGit (terminal UI)
- `<leader>gb` - Git blame
- `<leader>gc` - Git commit
- `<leader>gd` - Git diff / toggle deleted
- `<leader>gp` - Git push
- `<leader>hs` - Stage hunk
- `<leader>hr` - Reset hunk
- `<leader>hS` - Stage buffer
- `<leader>hp` - Preview hunk

## LSP & Code Intelligence

### Core LSP Functions
- `<leader>lf` - Format buffer
- `<leader>lD` - Go to declaration
- `<leader>ld` - Go to definition
- `<leader>lh` - Show hover information
- `<leader>li` - Go to implementation
- `<leader>ls` - Show signature help
- `<leader>lr` - Show references
- `<leader>lc` - Rename symbol
- `<leader>la` - Code actions
- `<leader>lj` - Next diagnostic
- `<leader>lk` - Previous diagnostic

### Diagnostic Viewing
- `<leader>le` - Show diagnostic popup
- `<leader>lq` - Add diagnostics to location list
- `<leader>lQ` - Add diagnostics to quickfix list
- `<leader>lv` - Toggle virtual text diagnostics
- `<leader>lt` - Toggle inlay hints
- `<leader>lH` - Toggle inlay hints (alternative)

### Quick LSP Actions
- `gd` - Go to definition
- `gr` - Go to references
- `K` - Show hover information

## Multi-cursor
- `<Leader>M` - Create cursor for word under cursor
- `<Leader>Mv` - Visual multi-cursor
- `<Leader>Mp` - Pattern-based multi-cursor
- `<Leader>Mu` - Under cursor multi-cursor

## Surround (nvim-surround)
- `ys{motion}{char}` - Add surroundings (e.g., `ysiw"` to surround word with quotes)
- `yss{char}` - Add surroundings to entire line
- `ds{char}` - Delete surroundings (e.g., `ds"` to remove quotes)
- `cs{old}{new}` - Change surroundings (e.g., `cs"'` to change quotes to single quotes)
- `S{char}` - Add surroundings in visual mode

## Enhanced Git (GitSigns)
- `]c` / `[c` - Navigate to next/previous git hunk
- `<leader>gs` - Stage current hunk
- `<leader>gr` - Reset current hunk
- `<leader>gS` - Stage entire buffer
- `<leader>gu` - Undo stage hunk
- `<leader>gR` - Reset entire buffer
- `<leader>gp` - Preview hunk changes
- `<leader>gb` - Show git blame for line
- `<leader>gB` - Toggle line blame display
- `<leader>gd` - Diff current file
- `<leader>gD` - Diff current file against HEAD~
- `<leader>gt` - Toggle deleted lines view

## Enhanced Editing
- `<leader>y` - Copy to system clipboard
- `<leader>Y` - Copy entire line to system clipboard
- `<leader>D` - Delete without yanking (preserves clipboard)
- `<leader>P` - Paste without yanking (in visual mode)
- `<leader>S` - Substitute word under cursor globally
- `<leader>ua` - Toggle auto-save

## Auto-pairs
Automatically closes brackets, quotes, etc. when typing. No manual keybindings needed.

## Debugging (DAP)

- `<leader>db` - Toggle breakpoint
- `<leader>dB` - Set conditional breakpoint
- `<leader>dc` - Continue debugging
- `<leader>ds` - Step over
- `<leader>di` - Step into
- `<leader>do` - Step out
- `<leader>dt` - Terminate debugging
- `<leader>du` - Toggle debug UI
- `<leader>de` - Evaluate expression
- `<leader>dl` - Run last debug session
- `<leader>dr` - Open debug REPL

## Testing (Neotest)

- `<leader>tf` - Test file
- `<leader>tn` - Test nearest
- `<leader>ts` - Test suite
- `<leader>tl` - Test last
- `<leader>tv` - Toggle test output panel
- `<leader>tS` - Test summary
- `<leader>to` - Test output

## Terminal

- `<leader>xf` - Float terminal
- `<leader>xh` - Horizontal terminal
- `<leader>xv` - Vertical terminal
- `<C-\>` - Toggle terminal
- `<leader>rc` - Rails console

## Trouble.nvim (Diagnostics & Lists)

- `<leader>xx` - All diagnostics (workspace)
- `<leader>xX` - Current buffer diagnostics
- `<leader>xs` - LSP symbols
- `<leader>xl` - LSP definitions/references
- `<leader>xL` - Location list
- `<leader>xQ` - Quickfix list

## Buffers

- `<leader>bn` - Next buffer
- `<leader>bp` - Previous buffer
- `<leader>bd` - Delete buffer
- `<Alt+,/.>` - Previous/next buffer
- `<Alt+1-9>` - Go to buffer by position

## UI Toggles

- `<leader>uu` - Toggle undotree
- `<leader>uh` - Clear search highlights
- `<leader>ub` - Toggle line blame
- `<leader>uf` - Toggle format on save
- `<C-d>/<C-u>` - Scroll with cursor centered

## Rails/Ruby

- `<leader>rv` - Controller/View toggle (vim-rails)
- `<leader>rV` - View Rails routes
- `<leader>rS` - View database schema
- `<leader>rm` - Go to model
- `<leader>rg` - Go to migration
- `<leader>rt` - Run Rake task
- `<leader>rc` - Rails console (terminal)
- `<leader>rs` - Rails server (terminal)
- `<leader>rd` - Debug nearest RSpec test
- `<leader>rD` - Debug RSpec file
- `<leader>rC` - Go to controller (HAML files only)

## UFO Folding

### Core Folding Commands
- `zR` - Open all folds
- `zM` - Close all folds
- `zr` - Open folds except certain kinds
- `zm` - Close folds with specific criteria
- `zp` - Peek inside fold (or show hover)
- `zO` - Close other folds, open current only
- `[z` - Go to previous fold (centered)
- `]z` - Go to next fold (centered)

### Standard Fold Commands (still work)
- `za` - Toggle current fold
- `zo` - Open current fold
- `zc` - Close current fold
- `zj` - Move to next fold
- `zk` - Move to previous fold

## Treesitter Text Objects

### Selection Text Objects
- `af/if` - Function (outer/inner)
- `ac/ic` - Class (outer/inner)
- `al/il` - Loop (outer/inner)
- `aa/ia` - Parameter (outer/inner)
- `ab/ib` - Block (outer/inner)
- `ad/id` - Conditional (outer/inner)
- `ar/ir` - Return statement (outer/inner)
- `as/is` - Statement (outer/inner)

### Navigation
- `]m/[m` - Next/previous method start
- `]M/[M` - Next/previous method end
- `]]/[[` - Next/previous class start
- `][/[]` - Next/previous class end
- `]l/[l` - Next/previous loop start
- `]L/[L` - Next/previous loop end
- `]a/[a` - Next/previous parameter
- `]d/[d` - Next/previous conditional

### Code Swapping
- `<leader>na` - Swap current parameter with next
- `<leader>pa` - Swap current parameter with previous
- `<leader>nf` - Swap current function with next
- `<leader>pf` - Swap current function with previous

## Harpoon (File Navigation)

- `<leader>ma` - Add file to harpoon
- `<leader>mh` - Show harpoon menu
- `<leader>1-4` - Jump to harpoon file 1-4
- `<C-S-P>` - Previous harpoon file
- `<C-S-N>` - Next harpoon file

## Sort/Swap

### Code Swapping (Treesitter)
- `<leader>na` - Swap current parameter with next
- `<leader>pa` - Swap current parameter with previous
- `<leader>nf` - Swap current function with next
- `<leader>pf` - Swap current function with previous

### Sorting
- `<leader>s` - Sort selected lines (visual mode)
- `<leader>S` - Substitute word under cursor globally

## Database

- `<leader>md` - Toggle Database UI

## Visual Mode Enhancements

- `J` - Move selected lines down
- `K` - Move selected lines up

## Navigation Enhancements

- `<C-d>` - Scroll down (cursor centered)
- `<C-u>` - Scroll up (cursor centered)
- `n` - Next search result (cursor centered)
- `N` - Previous search result (cursor centered)

## Functional Languages

### Haskell
- `<leader>rg` - Toggle GHCi REPL for package  
- `<leader>hf` - Toggle GHCi REPL for current file
- `<leader>rh` - Type check in GHCi
- `<leader>lh` - Hoogle lookup

### Elm
- `<leader>rm` - Elm Make
- `<leader>rE` - Elm Test
- `<leader>re` - Elm REPL
- `<leader>rd` - Elm Error Detail

### Elixir/Phoenix Development

#### File Navigation (`<leader>i`)
- `<leader>iv` - Related view
- `<leader>ic` - Jump to controller  
- `<leader>im` - Jump to model/schema
- `<leader>it` - Jump to test
- `<leader>is` - Jump to schema
- `<leader>il` - Jump to LiveView
- `<leader>iC` - Jump to context
- `<leader>iM` - Jump to migration
- `<leader>iR` - Jump to router
- `<leader>iE` - Jump to endpoint
- `<leader>iV` - Router file
- `<leader>iZ` - Database structure

#### Terminal Commands (`<leader>ix`)
- `<leader>ixc` - IEx console
- `<leader>ixs` - Phoenix server
- `<leader>ixt` - Mix test (stale)
- `<leader>ixl` - LiveBook server

### Elixir
- `<leader>rm` - Run mix command
- `<leader>ri` - IEx console
