# Neovim Configuration

A modern Neovim configuration focused on Ruby on Rails, Elixir/Phoenix, TypeScript, and C# development with LSP support, intelligent code completion, and a beautiful UI.

## Installation

This configuration is part of a Nix setup. To use independently:

1. Clone this repository to your Neovim config location:
   ```
   git clone https://github.com/yourusername/neovim-config ~/.config/nvim
   ```

2. Start Neovim and let it install plugins automatically:
   ```
   nvim
   ```

3. Install external dependencies for optimal experience:
   - Node.js (for LSP servers)
   - Ruby (for Ruby on Rails development)
   - Elixir & Erlang (for Elixir/Phoenix development)
   - Git (for version control features)
   - ripgrep (for Telescope file searching)
   - A Nerd Font (for icons)

## Structure

lib/nvim/
├── init.lua                      # Main entry point
├── lua/
│   ├── user/                     # Core user configuration
│   │   ├── keymap.lua            # Key mappings
│   │   ├── options.lua           # Neovim options
│   │   └── plugins.lua           # Plugin manager setup
│   │
│   └── plugins/                  # Plugin configurations
│       ├── init.lua              # Main plugins list
│       ├── ui.lua                # UI (colorscheme, statusline)
│       ├── lsp.lua               # Language server setup
│       ├── completion.lua        # Completion with blink-cmp
│       ├── treesitter.lua        # Syntax highlighting & text objects
│       ├── telescope.lua         # Fuzzy finder
│       ├── explorer.lua          # Oil file explorer
│       ├── git.lua               # Git integration
│       ├── format.lua            # Formatters and linters
│       ├── rails.lua             # Ruby on Rails specific plugins
│       ├── elixir.lua            # Elixir/Phoenix specific plugins
│       ├── none-ls.lua           # Diagnostics & formatting with LSP UI
│       ├── folding.lua           # Code folding with nvim-ufo
│       ├── which-key.lua         # Keybinding help popup
│       ├── marks.lua             # Enhanced marks
│       ├── bufferline.lua        # Buffer tabs with barbar
│       ├── undotree.lua          # Undo history visualization
│       └── trouble.lua           # Diagnostics viewer
│
└── after/
    └── ftplugin/                 # Filetype-specific settings
        ├── ruby.lua              # Ruby settings
        ├── python.lua            # Python settings
        ├── typescript.lua        # TypeScript settings
        ├── typescriptreact.lua   # TSX settings
        ├── cs.lua                # C# settings
        ├── yaml.lua              # YAML settings
        ├── json.lua              # JSON settings
        └── haml.lua              # HAML settings


## Key Features

- **LSP Integration**: Automatic language server setup for Ruby, Elixir, TypeScript, C#, Python, etc.
- **Intelligent Completion**: Using blink-cmp with snippets and LSP integration
- **Syntax Highlighting**: Enhanced with Treesitter
- **File Navigation**: Oil.nvim for seamless file browsing with framework-aware navigation
- **Keybinding Help**: Which-key shows available commands as you type
- **Git Integration**: Gitsigns and Fugitive for Git workflows
- **Tab Management**: Buffer tabs with barbar
- **Format & Lint**: Automatic code formatting and linting
- **Diagnostics**: Trouble for organized errors and warnings
- **Code Folding**: Smart folding with nvim-ufo and peek capability
- **Rails Development**: Specialized plugins for Ruby on Rails with vim-rails integration
- **Elixir/Phoenix Development**: Comprehensive Phoenix navigation, LiveView support, Mix integration, and LiveBook
- **Database Integration**: Built-in database viewing and management
- **Project Management**: Automatic project detection and session handling
- **Terminal Integration**: Floating terminals with specialized instances (Rails console, IEx, Phoenix server)
- **Enhanced Motion**: Quick navigation with Leap and Harpoon
- **Testing Integration**: Neotest with RSpec and ExUnit adapters
- **Advanced Debugging**: DAP support for Ruby and Elixir with visual debugging UI

## Keybindings

> Note: Space is the leader key (`<leader>`)

### Key Namespaces

| Prefix          | Purpose                      |
|-----------------|------------------------------|
| `<leader>f`     | Find (Telescope)             |
| `<leader>g`     | Git                          |
| `<leader>b`     | Buffer                       |
| `<leader>w`     | Window                       |
| `<leader>r`     | Rails/Ruby                   |
| `<leader>d`     | Diagnostics/Debug            |
| `<leader>t`     | Test                         |
| `<leader>x`     | Terminal                     |
| `<leader>a`     | Tabs                         |
| `<leader>i`     | Swap/Sort                    |
| `<leader>u`     | UI Toggles                   |
| `<leader>h`     | Hunks (Git)                  |
| `<leader>p`     | Project/Files                |
| `<leader>o`     | Oil File Explorer            |
| `<leader>v`     | Vimux                        |
| `<leader>m`     | Manage/Motion                |

### File Navigation

- `<leader>pv` - Open Oil file explorer
- `-` - Open parent directory in Oil
- `<leader>pf` - Open Oil in float window
- `<leader>os` - Open Oil in horizontal split
- `<leader>o|` - Open Oil in vertical split

### Search

- `<leader>ff` - Find files
- `<leader>fg` - Find text (grep)
- `<leader>fb` - Find buffers
- `<leader>fh` - Find help
- `<leader>fo` - Find recent files
- `<leader>fc` - Find current word
- `<leader>fd` - Find diagnostics
- `<leader>fs` - Find document symbols

### Windows & Tabs

- `<C-h/j/k/l>` - Navigate between windows/tmux panes
- `<leader>wv` - Split window vertically
- `<leader>wh` - Split window horizontally
- `<leader>we` - Make splits equal size
- `<leader>wx` - Close current split
- `<leader>ao` - Open new tab
- `<leader>ax` - Close current tab
- `<leader>an` - Next tab
- `<leader>ap` - Previous tab

### Buffers (with barbar)

- `Alt+,/.` - Previous/next buffer
- `Alt+1-9` - Go to buffer by position
- `Alt+c` - Close buffer
- `<leader>bc` - Close buffer
- `<leader>bp` - Previous buffer
- `<leader>bn` - Next buffer
- `<leader>bd` - Delete buffer

### Code

- `gd` - Go to definition
- `gr` - Go to references
- `gR` - List references (Trouble)
- `K` - Show hover information
- `<leader>ca` - Code actions
- `<leader>cf` - Format code
- `<leader>cl` - Refresh diagnostics
- `<leader>rn` - Rename symbol

### Git

- `<leader>gg` - Git status (fugitive)
- `<leader>gl` - LazyGit (terminal UI)
- `<leader>gb` - Git blame
- `<leader>gc` - Git commit
- `<leader>gd` - Git diff/toggle deleted
- `<leader>gp` - Git push
- `<leader>hs` - Stage hunk
- `<leader>hr` - Reset hunk
- `<leader>hS` - Stage buffer
- `<leader>hp` - Preview hunk
- `]c/[c` - Next/previous change

### Diagnostics (Trouble)

- `<leader>dd` - Toggle Trouble
- `<leader>dw` - Workspace diagnostics
- `<leader>df` - Document diagnostics
- `<leader>dq` - Quickfix list
- `<leader>dl` - Location list

### Debugging

- `<leader>db` - Toggle breakpoint
- `<leader>dc` - Continue debugging
- `<leader>ds` - Step over
- `<leader>di` - Step into
- `<leader>do` - Step out

### Folding

- `za` - Toggle current fold
- `zR` - Open all folds
- `zM` - Close all folds
- `zr` - Open one level of folds
- `zm` - Close one level of folds
- `zp` - Peek inside a fold

### UI Toggles

- `<leader>uu` - Toggle undotree
- `<leader>uh` - Clear search highlights
- `<leader>ub` - Toggle line blame

### Editor Features

- `<leader>is` - Sort functions alphabetically
- `<leader>iS` - Sort treesitter nodes
- `<leader>s` - Sort selected lines (visual mode)

### Marks

- `m[a-z]` - Set lowercase mark
- `m[A-Z]` - Set global mark
- `'[a-z]` - Jump to lowercase mark
- `'[A-Z]` - Jump to global mark
- `dm[a-z]` - Delete mark

### Terminal

- `<leader>xf` - Float terminal
- `<leader>xh` - Horizontal terminal
- `<leader>xv` - Vertical terminal
- `<C-\>` - Toggle terminal
- `<esc>/jk` - Exit terminal mode

### Rails Development

- `<leader>rs` - Start Rails server
- `<leader>rc` - Rails console
- `<leader>rd` - Debug nearest RSpec test
- `<leader>rD` - Debug all tests in file

### Elixir/Phoenix Development

- `<leader>is` - Start Phoenix server
- `<leader>ic` - IEx console  
- `<leader>it` - Mix test (stale)
- `<leader>il` - LiveBook server
- `<leader>id` - Debug nearest ExUnit test
- `<leader>iD` - Debug all ExUnit tests
- `<leader>iP` - Debug Phoenix server
- `<leader>rv` - Controller/View toggle
- `<leader>rV` - View Rails routes
- `<leader>rS` - View database schema
- `<leader>r` - Rails commands

### Testing

- `<leader>tf` - Test file
- `<leader>tn` - Test nearest
- `<leader>ts` - Test suite
- `<leader>tl` - Test last
- `<leader>tv` - Test visit

## Treesitter Text Objects

- `if/af` - Inside/around function
- `ic/ac` - Inside/around class
- `ia/aa` - Inside/around parameter
- `il/al` - Inside/around loop
- `ii/ai` - Inside/around conditional
- `ib/ab` - Inside/around block

### Movement with Treesitter

- `]f/]F` - Next function start/end
- `[f/[F` - Previous function start/end
- `]c/]C` - Next class start/end
- `[c/[C` - Previous class start/end

## Language Support

This configuration includes built-in support for:

- **Ruby/Rails**: Full LSP, formatting, linting, and Rails-specific commands
- **TypeScript/JavaScript**: LSP, Prettier, ESLint
- **C#**: LSP and formatting
- **Python**: LSP, Black formatter, Pylint
- **Lua**: LSP and formatting configured for Neovim development
- **HAML**: Syntax highlighting and linting
- **YAML/JSON**: LSP, formatting, and validation
- **Haskell**: LSP, stylish-haskell formatting, and HLint
- **Elm**: LSP and elm-format integration
- **Elixir**: LSP, mix format, and Credo linting

## Functional Language Support

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

### Elixir

- `<leader>rm` - Run mix command
- `<leader>rt` - Mix test (current file)
- `<leader>rT` - Mix test (all)
- `<leader>ri` - IEx console

## Plugin Highlights

- **oil.nvim**: File explorer integrated into buffer editing
- **nvim-ufo**: Advanced code folding with previews
- **barbar.nvim**: Buffer tabs with close buttons
- **which-key.nvim**: Keybinding popup for discovering commands
- **telescope.nvim**: Fuzzy finder for files, text, and more
- **trouble.nvim**: Interactive diagnostic and reference viewer
- **iswap.nvim**: Smart function and parameter manipulation
- **marks.nvim**: Visual marks in the gutter and navigation
- **undotree**: Visualize and navigate undo history

## Customization

To customize this configuration:

1. Edit `lua/user/options.lua` for Neovim settings
2. Edit `lua/user/keymap.lua` for custom keybindings
3. Add new plugins in `lua/plugins/init.lua`
4. Configure language-specific settings in `after/ftplugin/`

## Troubleshooting

- **Plugin Issues**: Run `:Lazy` to check plugin status
- **LSP Problems**: Run `:Mason` and ensure servers are installed
- **Formatting Issues**: Check `:ConformInfo` for formatter status
- **Diagnostics**: Use `:Trouble` to view all diagnostics in one place
- **Folding Issues**: Try `:lua require('ufo').setup()` to reload fold provider

## Tips

- Use `<leader>` and wait to see available commands with which-key
- Type `gd` on a function to jump to its definition, `gR` to see all references
- In Oil, press `-` to go up a directory, `Enter` to open a file
- Press `zp` to peek inside a fold without opening it
- Press `]f` and `[f` to jump between functions in a file

## Ruby on Rails Development

This configuration includes specialized tools and plugins for Ruby on Rails development.

### Rails-Specific Plugins

- **vim-rails**: Navigate and command your Rails projects
- **vim-ruby**: Enhanced Ruby syntax and indentation
- **vim-haml**: Support for HAML templates
- **vim-rspec**: RSpec integration for running tests
- **vim-dispatch**: Asynchronous command execution for tests
- **vim-textobj-rubyblock**: Text objects for Ruby blocks
- **nvim-treesitter-endwise**: Automatically add `end` after `do`, `def`, etc.

### Rails Commands

Access Rails commands with `<leader>r` followed by a command:

- `:Rails` - Run a Rails command
- `:Emodel [name]` - Edit a model
- `:Econtroller [name]` - Edit a controller
- `:Eview [name]` - Edit a view
- `:Emigration [name]` - Edit a migration
- `:Eschema` - Edit schema.rb
- `:Eroutes` - Edit routes.rb
- `:Ehelper [name]` - Edit a helper
- `:Emailer [name]` - Edit a mailer
- `:Ejob [name]` - Edit a job

### Testing with RSpec

Run tests with the following commands:

- `<leader>rs` - Run the current spec file
- `<leader>rt` - Run the spec under cursor
- `<leader>rl` - Run the last spec
- `<leader>ra` - Run all specs

### Ruby File Navigation

Jump between related files:

- `:A` - Alternate file (e.g., model to test, controller to view)
- `:R` - Related file (e.g., view to controller, migration to schema)
- `gf` - Go to file (works on paths, partials, models, etc.)

### Ruby LSP Features

The Ruby LSP provides:

- Code completion for Ruby and Rails
- Method definitions and documentation
- Inline diagnostics and error detection
- Go to definition/implementation for Rails components
- Code formatting with Rubocop

### Rails Development Tips

1. **Project Structure**: Use `:Oil` (`<leader>pv`) to navigate the Rails directory structure
2. **Fuzzy Finding**: Use `<leader>ff` to find files or `<leader>fg` to search project text
3. **Symbol Navigation**: Use `<leader>fs` to find symbols in current file
4. **Database Migrations**: Run migrations with `:Rails db:migrate`
5. **Console**: Open Rails console with `:Rails console`
6. **Generators**: Run Rails generators with `:Rails generate ...`
7. **ERB Templates**: Use `<leader>cf` to format ERB templates 
8. **Rubocop**: Automatically lint and fix Ruby code with `<leader>cf`
9. **Ruby Blocks**: Use `vir`/`var` to select inside/around Ruby blocks
10. **Text Objects**: `ir`/`ar` for Ruby blocks, `im`/`am` for method blocks

### Ruby Completion Tips

1. For better Ruby method completion, type the first few letters and press `<C-Space>`
2. Snippet completion works automatically (try typing `def` or `class`)
3. Rails-specific snippets available for controllers, models, etc.

### Debugging Ruby

1. Set breakpoints with `debugger` or `binding.pry`:
   - `;pry` snippet inserts `require 'pry'; binding.pry`
   - `;dbg` snippet inserts `require 'debug'; debugger`

2. Tmux integration for debugging:
   - `<leader>rd` - Run the current test with debugger
   - `<leader>rD` - Debug all tests in the current file
   - `<leader>rc` - Open Rails console
   - `<leader>rs` - Start Rails server
   - `<leader>vp` - Prompt for a command to run in tmux
   - `<leader>vl` - Run the last command again
   - `<leader>vi` - Inspect the tmux runner pane
   - `<leader>vz` - Zoom the tmux runner pane

3. Using pry effectively:
   - When debugging stops at a breakpoint, explore with `ls`, `find-method`, etc.
   - Use `next`, `step`, `continue` to navigate through code
   - Use `edit` to modify code during debugging
   - Use `whereami` to show current location

4. Rails specific debugging:
   - Debug API calls with: `curl localhost:3000/api/endpoint | jq` in tmux
   - Check SQL with: `ActiveRecord::Base.logger = Logger.new(STDOUT)`
   - View rendered partials: `puts "Rendering #{self.class.name} for #{@object}"`

#### Pry vs Debug

This configuration supports two Ruby debugging tools:

**Pry**:
- More powerful REPL with rich introspection capabilities
- Better for exploring object relationships and complex data structures
- Useful commands: `ls` (list methods/variables), `cd` (navigate object context), `find-method`
- Customizable with plugins and extensions
- Insert with `;pry` snippet: `require 'pry'; binding.pry`
- Better for exploratory debugging and learning about unfamiliar code

**Debug** (Standard Ruby debugger):
- Built into Ruby standard library since Ruby 3.1
- Traditional step debugger with commands like `step`, `next`, `continue`
- Lighter weight than Pry
- Better for tracing program flow
- More focused on tracking execution path
- Insert with `;dbg` snippet: `require 'debug'; debugger`
- Better for methodical debugging of known issues

**When to use which**:
- Use **Pry** when you need to explore complex objects or unfamiliar code
- Use **Debug** when you need to track execution flow step by step
- For Rails apps, Pry works better with more complex Rails objects
- For pure Ruby code with clear execution paths, Debug is often sufficient

Both tools can be used with the Tmux integration provided in this configuration.

## Advanced Features

### Project Management

This configuration includes project management and session handling:

#### Project Navigation

- `<leader>pp` - Open Telescope project finder
- Projects are detected automatically using LSP, .git, package.json, Gemfile, etc.
- The editor will automatically change to the project root directory

#### Session Management

- `<leader>ps` - Save the current session
- `<leader>pr` - Restore a previous session 
- `<leader>pd` - Delete the current session
- Sessions automatically save and restore when changing directories

### Terminal Integration

Enhanced terminal features for command execution:

#### Toggleterm

- `<C-\>` - Toggle floating terminal (main shortcut)
- `<leader>xf` - Open floating terminal
- `<leader>xh` - Open horizontal terminal at bottom
- `<leader>xv` - Open vertical terminal at side
- `<Esc>` or `jk` - Exit terminal mode

#### Special Terminals

- `<leader>gl` - Open LazyGit (full Git UI)
- `<leader>rc` - Open Rails console in floating terminal

### Enhanced Navigation

This setup includes advanced navigation tools:

#### Leap Motion

- `s` - Search forward and jump (2-character search)
- `S` - Search backward and jump
- `gs` - Search in all visible windows

How to use:
1. Press `s`
2. Type two characters to search for
3. Press the highlighted letter to jump to that match

#### Harpoon (Quick File Navigation)

- `<leader>ma` - Add current file to harpoon
- `<leader>mh` - Show harpoon menu
- `<leader>1-4` - Jump to harpoon file 1-4
- `<leader>fm` - Find harpoon files with Telescope

How to use:
1. Open files you frequently use in your project
2. Use `<leader>ma` to add them to harpoon
3. Use `<leader>mh` to see the list
4. Jump between them with `<leader>1`, `<leader>2`, etc.

### Database Integration

The configuration includes database viewing and management capabilities:

- `<leader>md` - Toggle database UI panel
- Database connections are automatically saved between sessions
- SQL completion in database query buffers
- Support for multiple database types (MySQL, PostgreSQL, SQLite, etc.)

How to use:
1. Open the DB UI with `<leader>md`
2. Press `?` in the UI for help
3. Add a connection (`a`) with your database connection string
4. Navigate databases, tables and run queries

### Visual Debugging

Enhanced debugging features for Ruby and other languages:

- `<leader>dd` - Toggle breakpoint
- `<leader>dc` - Start/continue debugging
- `<leader>ds` - Step over
- `<leader>di` - Step into
- `<leader>do` - Step out

The debugger includes:
- Visual breakpoint markers in the editor
- Variable inspection with hover
- Automatic UI for debug sessions
- Stacks, watches, and breakpoint management

### Rails Visual Tools

Additional Rails-specific tools beyond standard vim-rails:

- `<leader>rr` - View and search Rails routes
- `<leader>rm` - View database schema
- `<leader>rf` - Toggle between controller and view

These tools provide visual interfaces for Rails components that are typically text-only in standard setups.

## Getting Started with Functional Languages

### Haskell Development
1. Install GHC and Cabal/Stack: `nix-env -iA nixpkgs.ghc nixpkgs.cabal-install`
2. Open any `.hs` file to activate the Haskell language server
3. Use `<leader>rg` to start a GHCi REPL, `<leader>rf` for file-specific REPL
4. Type check with `<leader>rh` and look up documentation with `<leader>lh`

### Elm Development
1. Install Elm: `nix-env -iA nixpkgs.elmPackages.elm nixpkgs.elm-format`
2. Open any `.elm` file to activate the Elm language server
3. Use `<leader>rm` to build your Elm project
4. Test with `<leader>rE` and start a REPL with `<leader>re`

### Elixir Development
1. Install Elixir: `nix-env -iA nixpkgs.elixir nixpkgs.erlang`
2. Open any `.ex` or `.exs` file to activate the Elixir language server
3. Run mix commands with `<leader>rm`
4. Test the current file with `<leader>rt` and all tests with `<leader>rT`
5. Start an IEx console with `<leader>ri`
