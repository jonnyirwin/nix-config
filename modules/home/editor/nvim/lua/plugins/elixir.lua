return {
    -- Elixir syntax and indentation
    { 'elixir-editors/vim-elixir' },
    
    -- Mix integration for running Mix tasks
    {
        'mattreduce/vim-mix',
        ft = { 'elixir', 'eex', 'heex' },
        config = function()
            -- Mix convenience mappings (moved to <leader>i namespace to avoid conflicts)
            vim.keymap.set('n', '<leader>iX', ':Mix ', { desc = 'Mix: run task' })
            vim.keymap.set('n', '<leader>it', ':Mix test<CR>', { desc = 'Mix: run all tests' })
            vim.keymap.set('n', '<leader>if', ':Mix test %<CR>', { desc = 'Mix: test current file' })
            vim.keymap.set('n', '<leader>ic', ':Mix compile<CR>', { desc = 'Mix: compile' })
            vim.keymap.set('n', '<leader>imd', ':Mix deps.get<CR>', { desc = 'Mix: get dependencies' })
            vim.keymap.set('n', '<leader>ims', ':Mix phx.server<CR>', { desc = 'Mix: start Phoenix server' })
            vim.keymap.set('n', '<leader>imi', ':Mix iex -S mix<CR>', { desc = 'Mix: start IEx' })
            vim.keymap.set('n', '<leader>imp', ':Mix phx.new ', { desc = 'Mix: new Phoenix project' })
            vim.keymap.set('n', '<leader>img', ':Mix phx.gen.live ', { desc = 'Mix: generate LiveView' })
            vim.keymap.set('n', '<leader>imh', ':Mix phx.gen.html ', { desc = 'Mix: generate HTML context' })
            vim.keymap.set('n', '<leader>imj', ':Mix phx.gen.json ', { desc = 'Mix: generate JSON API' })
            vim.keymap.set('n', '<leader>imn', ':Mix ecto.gen.migration ', { desc = 'Mix: new migration' })
            vim.keymap.set('n', '<leader>imm', ':Mix ecto.migrate<CR>', { desc = 'Mix: run migrations' })
            vim.keymap.set('n', '<leader>imr', ':Mix ecto.rollback<CR>', { desc = 'Mix: rollback migration' })
            vim.keymap.set('n', '<leader>ime', ':Mix ecto.reset<CR>', { desc = 'Mix: reset database' })
        end,
    },
    
    -- Enhanced HEEx support for Phoenix LiveView templates - community maintained
    {
        'c-brenn/phoenix.vim',
        ft = { 'elixir', 'eex', 'heex', 'surface' },
        config = function()
            -- Phoenix file navigation - using <leader>i for Interactive/iEx/Elixir
            -- (avoiding <leader>e conflict with Oil file explorer)
            vim.keymap.set('n', '<leader>iev', ':Eview<CR>', { desc = 'Elixir: related view' })
            vim.keymap.set('n', '<leader>iec', ':Econtroller<CR>', { desc = 'Elixir: jump to controller' })
            vim.keymap.set('n', '<leader>iem', ':Emodel<CR>', { desc = 'Elixir: jump to model/schema' })
            vim.keymap.set('n', '<leader>iet', ':Etest<CR>', { desc = 'Elixir: jump to test' })
            vim.keymap.set('n', '<leader>ies', ':Eschema<CR>', { desc = 'Elixir: jump to schema' })
            vim.keymap.set('n', '<leader>iel', ':Elive<CR>', { desc = 'Elixir: jump to LiveView' })
            vim.keymap.set('n', '<leader>ieC', ':Econtext<CR>', { desc = 'Elixir: jump to context' })
            vim.keymap.set('n', '<leader>ieM', ':Emigration<CR>', { desc = 'Elixir: jump to migration' })
            vim.keymap.set('n', '<leader>ieR', ':Erouter<CR>', { desc = 'Elixir: jump to router' })
            vim.keymap.set('n', '<leader>ieE', ':Eendpoint<CR>', { desc = 'Elixir: jump to endpoint' })

            -- Phoenix project navigation
            vim.keymap.set('n', '<leader>ieV', ':edit lib/*/router.ex<CR>', { desc = 'Elixir: router' })
            vim.keymap.set('n', '<leader>ieZ', ':edit priv/repo/structure.sql<CR>', { desc = 'Elixir: database structure' })
        end,
    },

    -- Projectionist for intelligent file navigation
    {
        'tpope/vim-projectionist',
        ft = { 'elixir', 'eex', 'heex' },
        init = function()
            -- Phoenix projections for intelligent navigation
            vim.g.projectionist_heuristics = vim.tbl_extend("force", vim.g.projectionist_heuristics or {}, {
                ["mix.exs"] = {
                    -- Controllers
                    ["lib/*/controllers/*_controller.ex"] = {
                        type = "controller",
                        alternate = "test/{dirname}/controllers/{basename}_controller_test.exs",
                        template = {
                            "defmodule {dirname|camelcase|capitalize}.{basename|camelcase|capitalize}Controller do",
                            "  use {dirname|camelcase|capitalize}, :controller",
                            "",
                            "  def index(conn, _params) do",
                            "    render(conn, :index)",
                            "  end",
                            "end"
                        }
                    },
                    
                    -- LiveViews
                    ["lib/*/live/*_live.ex"] = {
                        type = "live",
                        alternate = "test/{dirname}/live/{basename}_live_test.exs",
                        template = {
                            "defmodule {dirname|camelcase|capitalize}.{basename|camelcase|capitalize}Live do",
                            "  use {dirname|camelcase|capitalize}, :live_view",
                            "",
                            "  def mount(_params, _session, socket) do",
                            "    {:ok, socket}",
                            "  end",
                            "end"
                        }
                    },
                    
                    -- Contexts
                    ["lib/*/contexts/*.ex"] = {
                        type = "context",
                        alternate = "test/{dirname}/contexts/{basename}_test.exs",
                    },
                    
                    -- Schemas
                    ["lib/*/schemas/*.ex"] = {
                        type = "schema", 
                        alternate = "test/{dirname}/schemas/{basename}_test.exs",
                        template = {
                            "defmodule {dirname|camelcase|capitalize}.{basename|camelcase|capitalize} do",
                            "  use Ecto.Schema",
                            "  import Ecto.Changeset",
                            "",
                            "  schema \"{basename|lowercase}s\" do",
                            "    timestamps()",
                            "  end",
                            "",
                            "  def changeset({basename|lowercase}, attrs) do",
                            "    {basename|lowercase}",
                            "    |> cast(attrs, [])",
                            "    |> validate_required([])",
                            "  end",
                            "end"
                        }
                    },
                    
                    -- Templates
                    ["lib/*/templates/*/*.html.heex"] = {
                        type = "template",
                        alternate = "lib/{dirname}/controllers/{basename}_controller.ex"
                    },
                    
                    -- Tests
                    ["test/*_test.exs"] = {
                        type = "test",
                        alternate = "lib/{}.ex"
                    },
                    
                    -- Migrations
                    ["priv/repo/migrations/*.exs"] = {
                        type = "migration"
                    },
                    
                    -- Router
                    ["lib/*/router.ex"] = {
                        type = "router"
                    }
                }
            })
        end,
    },

    -- Better HEEx syntax highlighting
    {
        'mitchellh/vim-misc',
        ft = { 'heex', 'eex' },
    },
}