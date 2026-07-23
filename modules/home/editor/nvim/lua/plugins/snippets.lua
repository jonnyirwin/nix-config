return {
    {
        "L3MON4D3/LuaSnip",
        version = "v2.*",
        build = "make install_jsregexp",
        dependencies = {
            "rafamadriz/friendly-snippets",
            "honza/vim-snippets", -- Additional snippets including Rails
        },
        config = function()
            local luasnip = require("luasnip")
            
            -- Load snippets from friendly-snippets
            require("luasnip.loaders.from_vscode").lazy_load()
            
            -- Load snippets from vim-snippets
            require("luasnip.loaders.from_snipmate").lazy_load()
            
            -- Custom Rails snippets
            luasnip.add_snippets("ruby", {
                -- Basic Ruby snippets
                luasnip.snippet("def", {
                    luasnip.text_node("def "),
                    luasnip.insert_node(1, "method_name"),
                    luasnip.text_node({"", "  "}),
                    luasnip.insert_node(2, "# TODO"),
                    luasnip.text_node({"", "end"}),
                }),
                
                -- Debugging snippets
                luasnip.snippet("pry", {
                    luasnip.text_node("require 'pry'; binding.pry"),
                }),
                luasnip.snippet("dbg", {
                    luasnip.text_node("require 'debug'; debugger"),
                }),
                luasnip.snippet("pp", {
                    luasnip.text_node("puts "),
                    luasnip.insert_node(1, "variable"),
                    luasnip.text_node(".inspect"),
                }),
                luasnip.snippet("log", {
                    luasnip.text_node("Rails.logger.info "),
                    luasnip.insert_node(1, '"Debug message"'),
                }),
                
                -- Rails Model snippets
                luasnip.snippet("val", {
                    luasnip.text_node("validates :"),
                    luasnip.insert_node(1, "attribute"),
                    luasnip.text_node(", "),
                    luasnip.insert_node(2, "presence: true"),
                }),
                luasnip.snippet("has_many", {
                    luasnip.text_node("has_many :"),
                    luasnip.insert_node(1, "association"),
                }),
                luasnip.snippet("belongs_to", {
                    luasnip.text_node("belongs_to :"),
                    luasnip.insert_node(1, "association"),
                }),
                luasnip.snippet("scope", {
                    luasnip.text_node("scope :"),
                    luasnip.insert_node(1, "name"),
                    luasnip.text_node(", -> { "),
                    luasnip.insert_node(2, "where(active: true)"),
                    luasnip.text_node(" }"),
                }),
                
                -- Rails Controller snippets
                luasnip.snippet("before", {
                    luasnip.text_node("before_action :"),
                    luasnip.insert_node(1, "method_name"),
                }),
                luasnip.snippet("private", {
                    luasnip.text_node({"", "private", "", ""}),
                    luasnip.insert_node(1),
                }),
                luasnip.snippet("strong", {
                    luasnip.text_node("params.require(:"),
                    luasnip.insert_node(1, "model"),
                    luasnip.text_node(").permit("),
                    luasnip.insert_node(2, ":name, :email"),
                    luasnip.text_node(")"),
                }),
                luasnip.snippet("redirect", {
                    luasnip.text_node("redirect_to "),
                    luasnip.insert_node(1, "path"),
                    luasnip.text_node(", notice: '"),
                    luasnip.insert_node(2, "Success message"),
                    luasnip.text_node("'"),
                }),
                luasnip.snippet("render", {
                    luasnip.text_node("render :"),
                    luasnip.insert_node(1, "template"),
                    luasnip.text_node(", status: :"),
                    luasnip.insert_node(2, "unprocessable_entity"),
                }),
                
                -- Rails Route snippets
                luasnip.snippet("resources", {
                    luasnip.text_node("resources :"),
                    luasnip.insert_node(1, "model"),
                }),
                luasnip.snippet("get", {
                    luasnip.text_node("get '"),
                    luasnip.insert_node(1, "path"),
                    luasnip.text_node("', to: '"),
                    luasnip.insert_node(2, "controller#action"),
                    luasnip.text_node("'"),
                }),
                luasnip.snippet("post", {
                    luasnip.text_node("post '"),
                    luasnip.insert_node(1, "path"),
                    luasnip.text_node("', to: '"),
                    luasnip.insert_node(2, "controller#action"),
                    luasnip.text_node("'"),
                }),
                
                -- Rails Migration snippets
                luasnip.snippet("migration", {
                    luasnip.text_node({"class ", ""}),
                    luasnip.insert_node(1, "MigrationName"),
                    luasnip.text_node({" < ActiveRecord::Migration[7.0]", "  def change", "    "}),
                    luasnip.insert_node(2, "# migration code"),
                    luasnip.text_node({"", "  end", "end"}),
                }),
                luasnip.snippet("add_column", {
                    luasnip.text_node("add_column :"),
                    luasnip.insert_node(1, "table"),
                    luasnip.text_node(", :"),
                    luasnip.insert_node(2, "column"),
                    luasnip.text_node(", :"),
                    luasnip.insert_node(3, "string"),
                }),
                luasnip.snippet("create_table", {
                    luasnip.text_node("create_table :"),
                    luasnip.insert_node(1, "table_name"),
                    luasnip.text_node({" do |t|", "  "}),
                    luasnip.insert_node(2, "t.string :name"),
                    luasnip.text_node({"", "  t.timestamps", "end"}),
                }),
                
                -- RSpec snippets
                luasnip.snippet("describe", {
                    luasnip.text_node("describe '"),
                    luasnip.insert_node(1, "feature"),
                    luasnip.text_node({"' do", "  "}),
                    luasnip.insert_node(2, "# tests"),
                    luasnip.text_node({"", "end"}),
                }),
                luasnip.snippet("context", {
                    luasnip.text_node("context '"),
                    luasnip.insert_node(1, "when condition"),
                    luasnip.text_node({"' do", "  "}),
                    luasnip.insert_node(2, "# tests"),
                    luasnip.text_node({"", "end"}),
                }),
                luasnip.snippet("it", {
                    luasnip.text_node("it '"),
                    luasnip.insert_node(1, "should do something"),
                    luasnip.text_node({"' do", "  "}),
                    luasnip.insert_node(2, "# test code"),
                    luasnip.text_node({"", "end"}),
                }),
                luasnip.snippet("expect", {
                    luasnip.text_node("expect("),
                    luasnip.insert_node(1, "subject"),
                    luasnip.text_node(").to "),
                    luasnip.insert_node(2, "eq(value)"),
                }),
                luasnip.snippet("let", {
                    luasnip.text_node("let(:"),
                    luasnip.insert_node(1, "variable"),
                    luasnip.text_node(") { "),
                    luasnip.insert_node(2, "value"),
                    luasnip.text_node(" }"),
                }),
                
                -- Factory Bot snippets
                luasnip.snippet("factory", {
                    luasnip.text_node("factory :"),
                    luasnip.insert_node(1, "model"),
                    luasnip.text_node({" do", "  "}),
                    luasnip.insert_node(2, "name { 'Test Name' }"),
                    luasnip.text_node({"", "end"}),
                }),
                luasnip.snippet("create", {
                    luasnip.text_node("create(:"),
                    luasnip.insert_node(1, "factory"),
                    luasnip.text_node(")"),
                }),
                luasnip.snippet("build", {
                    luasnip.text_node("build(:"),
                    luasnip.insert_node(1, "factory"),
                    luasnip.text_node(")"),
                }),
                
                -- Rails Console shortcuts
                luasnip.snippet("reload!", {
                    luasnip.text_node("reload!"),
                }),
                luasnip.snippet("User.find", {
                    luasnip.text_node("User.find("),
                    luasnip.insert_node(1, "id"),
                    luasnip.text_node(")"),
                }),
                luasnip.snippet("where", {
                    luasnip.text_node("where("),
                    luasnip.insert_node(1, "condition"),
                    luasnip.text_node(")"),
                }),
            })
            
            -- Custom Elixir/Phoenix snippets
            luasnip.add_snippets("elixir", {
                -- Basic Elixir snippets
                luasnip.snippet("def", {
                    luasnip.text_node("def "),
                    luasnip.insert_node(1, "function_name"),
                    luasnip.text_node("("),
                    luasnip.insert_node(2, "params"),
                    luasnip.text_node({") do", "  "}),
                    luasnip.insert_node(3, "# TODO"),
                    luasnip.text_node({"", "end"}),
                }),
                luasnip.snippet("defp", {
                    luasnip.text_node("defp "),
                    luasnip.insert_node(1, "function_name"),
                    luasnip.text_node("("),
                    luasnip.insert_node(2, "params"),
                    luasnip.text_node({") do", "  "}),
                    luasnip.insert_node(3, "# TODO"),
                    luasnip.text_node({"", "end"}),
                }),
                luasnip.snippet("defmodule", {
                    luasnip.text_node("defmodule "),
                    luasnip.insert_node(1, "ModuleName"),
                    luasnip.text_node({" do", "  "}),
                    luasnip.insert_node(2, "# TODO"),
                    luasnip.text_node({"", "end"}),
                }),
                
                -- Debugging snippets
                luasnip.snippet("io", {
                    luasnip.text_node("IO.inspect("),
                    luasnip.insert_node(1, "variable"),
                    luasnip.text_node(', label: "'),
                    luasnip.insert_node(2, "debug"),
                    luasnip.text_node('")'),
                }),
                luasnip.snippet("iop", {
                    luasnip.text_node("IO.puts("),
                    luasnip.insert_node(1, '"Debug message"'),
                    luasnip.text_node(")"),
                }),
                luasnip.snippet("dbg", {
                    luasnip.text_node("require IEx; IEx.pry()"),
                }),
                luasnip.snippet("log", {
                    luasnip.text_node("Logger.info("),
                    luasnip.insert_node(1, '"Debug message"'),
                    luasnip.text_node(")"),
                }),
                
                -- GenServer snippets
                luasnip.snippet("genserver", {
                    luasnip.text_node({"defmodule "}),
                    luasnip.insert_node(1, "MyGenServer"),
                    luasnip.text_node({" do", "  use GenServer", "", "  # Client API", "", "  def start_link(opts) do", "    GenServer.start_link(__MODULE__, opts, name: __MODULE__)", "  end", "", "  def get_state do", "    GenServer.call(__MODULE__, :get_state)", "  end", "", "  # Server Callbacks", "", "  @impl true", "  def init(opts) do", "    {:ok, "}),
                    luasnip.insert_node(2, "%{}"),
                    luasnip.text_node({"}", "  end", "", "  @impl true", "  def handle_call(:get_state, _from, state) do", "    {:reply, state, state}", "  end", "", "  @impl true", "  def handle_cast(_msg, state) do", "    {:noreply, state}", "  end", "end"}),
                }),
                luasnip.snippet("gencall", {
                    luasnip.text_node("GenServer.call("),
                    luasnip.insert_node(1, "server"),
                    luasnip.text_node(", "),
                    luasnip.insert_node(2, "message"),
                    luasnip.text_node(")"),
                }),
                luasnip.snippet("gencast", {
                    luasnip.text_node("GenServer.cast("),
                    luasnip.insert_node(1, "server"),
                    luasnip.text_node(", "),
                    luasnip.insert_node(2, "message"),
                    luasnip.text_node(")"),
                }),
                
                -- Phoenix Controller snippets
                luasnip.snippet("controller", {
                    luasnip.text_node("defmodule "),
                    luasnip.insert_node(1, "MyApp"),
                    luasnip.text_node("Web."),
                    luasnip.insert_node(2, "PageController"),
                    luasnip.text_node({" do", "  use "}),
                    luasnip.insert_node(3, "MyApp"),
                    luasnip.text_node({"Web, :controller", "", "  def index(conn, _params) do", "    render(conn, :index)", "  end", "end"}),
                }),
                luasnip.snippet("action", {
                    luasnip.text_node("def "),
                    luasnip.insert_node(1, "index"),
                    luasnip.text_node({"(conn, params) do", "  "}),
                    luasnip.insert_node(2, "render(conn, :index)"),
                    luasnip.text_node({"", "end"}),
                }),
                luasnip.snippet("render", {
                    luasnip.text_node("render(conn, :"),
                    luasnip.insert_node(1, "index"),
                    luasnip.text_node(")"),
                }),
                luasnip.snippet("redirect", {
                    luasnip.text_node("redirect(conn, to: "),
                    luasnip.insert_node(1, "~p\"/\""),
                    luasnip.text_node(")"),
                }),
                luasnip.snippet("json", {
                    luasnip.text_node("json(conn, "),
                    luasnip.insert_node(1, "%{data: data}"),
                    luasnip.text_node(")"),
                }),
                
                -- Phoenix LiveView snippets
                luasnip.snippet("liveview", {
                    luasnip.text_node("defmodule "),
                    luasnip.insert_node(1, "MyApp"),
                    luasnip.text_node("Web."),
                    luasnip.insert_node(2, "PageLive"),
                    luasnip.text_node({" do", "  use "}),
                    luasnip.insert_node(3, "MyApp"),
                    luasnip.text_node({"Web, :live_view", "", "  @impl true", "  def mount(_params, _session, socket) do", "    {:ok, assign(socket, "}),
                    luasnip.insert_node(4, "count: 0"),
                    luasnip.text_node({")", "  end", "", "  @impl true", "  def handle_event(\""}),
                    luasnip.insert_node(5, "increment"),
                    luasnip.text_node({"\", _params, socket) do", "    {:noreply, assign(socket, count: socket.assigns.count + 1)}", "  end", "end"}),
                }),
                luasnip.snippet("mount", {
                    luasnip.text_node({"@impl true", "def mount(_params, _session, socket) do", "  {:ok, assign(socket, "}),
                    luasnip.insert_node(1, "data: []"),
                    luasnip.text_node({")", "end"}),
                }),
                luasnip.snippet("handle_event", {
                    luasnip.text_node({"@impl true", "def handle_event(\""}),
                    luasnip.insert_node(1, "event_name"),
                    luasnip.text_node({"\", params, socket) do", "  "}),
                    luasnip.insert_node(2, "{:noreply, socket}"),
                    luasnip.text_node({"", "end"}),
                }),
                luasnip.snippet("assign", {
                    luasnip.text_node("assign(socket, "),
                    luasnip.insert_node(1, "key: value"),
                    luasnip.text_node(")"),
                }),
                luasnip.snippet("push_event", {
                    luasnip.text_node("push_event(socket, \""),
                    luasnip.insert_node(1, "event_name"),
                    luasnip.text_node("\", "),
                    luasnip.insert_node(2, "%{}"),
                    luasnip.text_node(")"),
                }),
                
                -- Ecto Schema snippets
                luasnip.snippet("schema", {
                    luasnip.text_node("defmodule "),
                    luasnip.insert_node(1, "MyApp"),
                    luasnip.text_node("."),
                    luasnip.insert_node(2, "User"),
                    luasnip.text_node({" do", "  use Ecto.Schema", "  import Ecto.Changeset", "", "  schema \""}),
                    luasnip.insert_node(3, "users"),
                    luasnip.text_node({"\" do", "    field :name, :string", "    field :email, :string", "    ", "    timestamps()", "  end", "", "  def changeset("}),
                    luasnip.insert_node(4, "user"),
                    luasnip.text_node({", attrs) do", "    "}),
                    luasnip.insert_node(5, "user"),
                    luasnip.text_node({"", "    |> cast(attrs, [:name, :email])", "    |> validate_required([:name, :email])", "  end", "end"}),
                }),
                luasnip.snippet("changeset", {
                    luasnip.text_node("def changeset("),
                    luasnip.insert_node(1, "struct"),
                    luasnip.text_node({", attrs) do", "  "}),
                    luasnip.insert_node(2, "struct"),
                    luasnip.text_node({"", "  |> cast(attrs, ["}),
                    luasnip.insert_node(3, ":field"),
                    luasnip.text_node({"])", "  |> validate_required(["}),
                    luasnip.insert_node(4, ":field"),
                    luasnip.text_node({"])", "end"}),
                }),
                luasnip.snippet("field", {
                    luasnip.text_node("field :"),
                    luasnip.insert_node(1, "name"),
                    luasnip.text_node(", :"),
                    luasnip.insert_node(2, "string"),
                }),
                luasnip.snippet("belongs_to", {
                    luasnip.text_node("belongs_to :"),
                    luasnip.insert_node(1, "user"),
                    luasnip.text_node(", "),
                    luasnip.insert_node(2, "MyApp.User"),
                }),
                luasnip.snippet("has_many", {
                    luasnip.text_node("has_many :"),
                    luasnip.insert_node(1, "posts"),
                    luasnip.text_node(", "),
                    luasnip.insert_node(2, "MyApp.Post"),
                }),
                luasnip.snippet("has_one", {
                    luasnip.text_node("has_one :"),
                    luasnip.insert_node(1, "profile"),
                    luasnip.text_node(", "),
                    luasnip.insert_node(2, "MyApp.Profile"),
                }),
                
                -- Ecto Query snippets
                luasnip.snippet("from", {
                    luasnip.text_node("from "),
                    luasnip.insert_node(1, "u"),
                    luasnip.text_node(" in "),
                    luasnip.insert_node(2, "User"),
                    luasnip.text_node(", "),
                    luasnip.insert_node(3, "select: u"),
                }),
                luasnip.snippet("where", {
                    luasnip.text_node("where: "),
                    luasnip.insert_node(1, "u.active == true"),
                }),
                luasnip.snippet("select", {
                    luasnip.text_node("select: "),
                    luasnip.insert_node(1, "u"),
                }),
                luasnip.snippet("preload", {
                    luasnip.text_node("preload: "),
                    luasnip.insert_node(1, ":posts"),
                }),
                
                -- Phoenix Context snippets
                luasnip.snippet("context", {
                    luasnip.text_node("defmodule "),
                    luasnip.insert_node(1, "MyApp"),
                    luasnip.text_node("."),
                    luasnip.insert_node(2, "Accounts"),
                    luasnip.text_node({" do", "  alias "}),
                    luasnip.insert_node(3, "MyApp"),
                    luasnip.text_node(".Repo", "  alias "),
                    luasnip.insert_node(4, "MyApp"),
                    luasnip.text_node("."),
                    luasnip.insert_node(5, "User"),
                    luasnip.text_node({"", "", "  def list_users do", "    Repo.all(User)", "  end", "", "  def get_user!(id), do: Repo.get!(User, id)", "", "  def create_user(attrs \\\\ %{}) do", "    %User{}", "    |> User.changeset(attrs)", "    |> Repo.insert()", "  end", "", "  def update_user(%User{} = user, attrs) do", "    user", "    |> User.changeset(attrs)", "    |> Repo.update()", "  end", "", "  def delete_user(%User{} = user) do", "    Repo.delete(user)", "  end", "end"}),
                }),
                
                -- Phoenix Router snippets
                luasnip.snippet("resources", {
                    luasnip.text_node("resources \"/"),
                    luasnip.insert_node(1, "users"),
                    luasnip.text_node("\", "),
                    luasnip.insert_node(2, "UserController"),
                }),
                luasnip.snippet("get", {
                    luasnip.text_node("get \"/"),
                    luasnip.insert_node(1, "path"),
                    luasnip.text_node("\", "),
                    luasnip.insert_node(2, "Controller"),
                    luasnip.text_node(", :"),
                    luasnip.insert_node(3, "action"),
                }),
                luasnip.snippet("post", {
                    luasnip.text_node("post \"/"),
                    luasnip.insert_node(1, "path"),
                    luasnip.text_node("\", "),
                    luasnip.insert_node(2, "Controller"),
                    luasnip.text_node(", :"),
                    luasnip.insert_node(3, "action"),
                }),
                luasnip.snippet("live", {
                    luasnip.text_node("live \"/"),
                    luasnip.insert_node(1, "path"),
                    luasnip.text_node("\", "),
                    luasnip.insert_node(2, "PageLive"),
                    luasnip.text_node(", :"),
                    luasnip.insert_node(3, "index"),
                }),
                
                -- ExUnit test snippets
                luasnip.snippet("test", {
                    luasnip.text_node("test \""),
                    luasnip.insert_node(1, "description"),
                    luasnip.text_node({"\" do", "  "}),
                    luasnip.insert_node(2, "# test code"),
                    luasnip.text_node({"", "end"}),
                }),
                luasnip.snippet("describe", {
                    luasnip.text_node("describe \""),
                    luasnip.insert_node(1, "feature"),
                    luasnip.text_node({"\" do", "  "}),
                    luasnip.insert_node(2, "# tests"),
                    luasnip.text_node({"", "end"}),
                }),
                luasnip.snippet("assert", {
                    luasnip.text_node("assert "),
                    luasnip.insert_node(1, "condition"),
                }),
                luasnip.snippet("assert_eq", {
                    luasnip.text_node("assert "),
                    luasnip.insert_node(1, "actual"),
                    luasnip.text_node(" == "),
                    luasnip.insert_node(2, "expected"),
                }),
                luasnip.snippet("refute", {
                    luasnip.text_node("refute "),
                    luasnip.insert_node(1, "condition"),
                }),
                luasnip.snippet("setup", {
                    luasnip.text_node({"setup do", "  "}),
                    luasnip.insert_node(1, "# setup code"),
                    luasnip.text_node({"", "end"}),
                }),
                
                -- Mix/Hex snippets
                luasnip.snippet("mix_task", {
                    luasnip.text_node("defmodule Mix.Tasks."),
                    luasnip.insert_node(1, "MyTask"),
                    luasnip.text_node({" do", "  use Mix.Task", "", "  @shortdoc \""}),
                    luasnip.insert_node(2, "Task description"),
                    luasnip.text_node({"\"", "", "  def run(args) do", "    "}),
                    luasnip.insert_node(3, "# task implementation"),
                    luasnip.text_node({"", "  end", "end"}),
                }),
                
                -- Common patterns
                luasnip.snippet("pipe", {
                    luasnip.insert_node(1, "value"),
                    luasnip.text_node({"", "|> "}),
                    luasnip.insert_node(2, "function()"),
                }),
                luasnip.snippet("case", {
                    luasnip.text_node("case "),
                    luasnip.insert_node(1, "expression"),
                    luasnip.text_node({" do", "  "}),
                    luasnip.insert_node(2, "pattern"),
                    luasnip.text_node(" -> "),
                    luasnip.insert_node(3, "result"),
                    luasnip.text_node({"", "end"}),
                }),
                luasnip.snippet("with", {
                    luasnip.text_node("with "),
                    luasnip.insert_node(1, "{:ok, value} <- function()"),
                    luasnip.text_node({" do", "  "}),
                    luasnip.insert_node(2, "# success case"),
                    luasnip.text_node({"", "end"}),
                }),
                luasnip.snippet("try", {
                    luasnip.text_node({"try do", "  "}),
                    luasnip.insert_node(1, "# code that might fail"),
                    luasnip.text_node({"", "rescue", "  "}),
                    luasnip.insert_node(2, "error"),
                    luasnip.text_node(" -> "),
                    luasnip.insert_node(3, "# handle error"),
                    luasnip.text_node({"", "end"}),
                }),
            })
            
            -- Keybindings for LuaSnip (using Tab/Shift-Tab for navigation)
            vim.keymap.set({"i", "s"}, "<Tab>", function()
                if luasnip.expand_or_jumpable() then
                    luasnip.expand_or_jump()
                end
            end, { desc = "Expand or jump snippet forward" })
            
            vim.keymap.set({"i", "s"}, "<S-Tab>", function()
                if luasnip.jumpable(-1) then
                    luasnip.jump(-1)
                end
            end, { desc = "Jump back in snippet" })
        end,
    },
}
