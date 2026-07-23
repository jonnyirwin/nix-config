-- Advanced workspace context utilities for CodeCompanion
-- This module provides VS Code-like workspace awareness for Neovim + CodeCompanion

local M = {}

-- Get Rails project structure
function M.get_rails_structure()
    local structure = {
        models = vim.fn.glob("app/models/*.rb", false, true),
        controllers = vim.fn.glob("app/controllers/*.rb", false, true),
        views = vim.fn.glob("app/views/**/*.erb", false, true),
        routes = vim.fn.filereadable("config/routes.rb") == 1 and "config/routes.rb" or nil,
        schema = vim.fn.filereadable("db/schema.rb") == 1 and "db/schema.rb" or nil,
        gemfile = vim.fn.filereadable("Gemfile") == 1 and "Gemfile" or nil,
        tests = vim.fn.glob("spec/**/*_spec.rb", false, true),
        migrations = vim.fn.glob("db/migrate/*.rb", false, true),
    }
    
    return structure
end

-- Get project summary for AI context
function M.get_project_summary()
    local cwd = vim.fn.getcwd()
    local git_root = vim.fn.systemlist("git rev-parse --show-toplevel 2>/dev/null")[1]
    local current_file = vim.fn.expand('%:.')
    local file_type = vim.bo.filetype
    
    -- Check if it's a Rails project
    local is_rails = vim.fn.filereadable("config/application.rb") == 1
    
    local summary = {
        project_root = cwd,
        git_root = git_root,
        current_file = current_file,
        file_type = file_type,
        is_rails = is_rails,
        structure = is_rails and M.get_rails_structure() or nil
    }
    
    return summary
end

-- Format project context for AI
function M.format_context_for_ai()
    local summary = M.get_project_summary()
    local context = {}
    
    table.insert(context, "=== WORKSPACE CONTEXT ===")
    table.insert(context, "Project Root: " .. summary.project_root)
    if summary.git_root then
        table.insert(context, "Git Root: " .. summary.git_root)
    end
    table.insert(context, "Current File: " .. summary.current_file .. " (" .. summary.file_type .. ")")
    
    if summary.is_rails then
        table.insert(context, "\n=== RAILS PROJECT STRUCTURE ===")
        if summary.structure.gemfile then
            table.insert(context, "Gemfile: ✓")
        end
        if summary.structure.routes then
            table.insert(context, "Routes: ✓")
        end
        if summary.structure.schema then
            table.insert(context, "Schema: ✓")
        end
        
        table.insert(context, "Models: " .. #summary.structure.models)
        table.insert(context, "Controllers: " .. #summary.structure.controllers)
        table.insert(context, "Views: " .. #summary.structure.views)
        table.insert(context, "Tests: " .. #summary.structure.tests)
        table.insert(context, "Migrations: " .. #summary.structure.migrations)
    end
    
    table.insert(context, "\n=== CURRENT CONTEXT ===")
    
    return table.concat(context, "\n") .. "\n\n"
end

-- Get related files based on current file
function M.get_related_files()
    local current_file = vim.fn.expand('%:.')
    local related = {}
    
    -- Rails-specific relationships
    if string.match(current_file, "app/models/(.+)%.rb") then
        local model_name = string.match(current_file, "app/models/(.+)%.rb")
        table.insert(related, "app/controllers/" .. model_name .. "s_controller.rb")
        table.insert(related, "spec/models/" .. model_name .. "_spec.rb")
        table.insert(related, "spec/factories/" .. model_name .. "s.rb")
    elseif string.match(current_file, "app/controllers/(.+)_controller%.rb") then
        local controller_name = string.match(current_file, "app/controllers/(.+)_controller%.rb")
        local model_name = string.gsub(controller_name, "s$", "") -- Remove plural 's'
        table.insert(related, "app/models/" .. model_name .. ".rb")
        table.insert(related, "app/views/" .. controller_name .. "/")
        table.insert(related, "spec/controllers/" .. controller_name .. "_controller_spec.rb")
        table.insert(related, "spec/requests/" .. controller_name .. "_spec.rb")
    elseif string.match(current_file, "spec/.*_spec%.rb") then
        local spec_file = string.match(current_file, "spec/(.*)_spec%.rb")
        table.insert(related, "app/" .. spec_file .. ".rb")
    end
    
    -- Filter to only existing files
    local existing_related = {}
    for _, file in ipairs(related) do
        if vim.fn.filereadable(file) == 1 then
            table.insert(existing_related, file)
        elseif vim.fn.isdirectory(file) == 1 then
            table.insert(existing_related, file .. " (directory)")
        end
    end
    
    return existing_related
end

-- Smart file picker for context
function M.pick_context_files()
    local related = M.get_related_files()
    
    if #related == 0 then
        print("No related files found")
        return
    end
    
    vim.ui.select(related, {
        prompt = "Add files to CodeCompanion context:",
    }, function(choice)
        if choice and not string.match(choice, "directory") then
            -- Open the file and add to context
            vim.cmd("edit " .. choice)
            vim.defer_fn(function()
                vim.cmd("CodeCompanionChat Add")
            end, 100)
        end
    end)
end

-- Batch add multiple files to context
function M.add_rails_context_files()
    local structure = M.get_rails_structure()
    local key_files = {}
    
    if structure.routes then table.insert(key_files, structure.routes) end
    if structure.schema then table.insert(key_files, structure.schema) end
    if structure.gemfile then table.insert(key_files, structure.gemfile) end
    
    -- Add current file's related files
    local related = M.get_related_files()
    for _, file in ipairs(related) do
        if not string.match(file, "directory") then
            table.insert(key_files, file)
        end
    end
    
    -- Build the full context text
    local context = M.format_context_for_ai()
    local full_text = context
    
    -- Mention key files that should be considered
    if #key_files > 0 then
        full_text = full_text .. "KEY FILES TO CONSIDER:\n" .. table.concat(key_files, "\n") .. "\n\n"
    end
    full_text = full_text .. "Please analyze this Rails project context. What would you like to help me with?"
    
    -- Use the proper CodeCompanion API
    require("codecompanion").chat({
        args = { args = full_text }
    })
end

-- Create a workspace-aware chat template
function M.create_workspace_template()
    local summary = M.get_project_summary()
    local template = M.format_context_for_ai()
    
    -- Add common Rails patterns to help the AI understand the codebase
    if summary.is_rails then
        template = template .. "=== RAILS CONVENTIONS TO FOLLOW ===\n"
        template = template .. "- Follow Rails naming conventions\n"
        template = template .. "- Use strong parameters in controllers\n"
        template = template .. "- Write comprehensive tests\n"
        template = template .. "- Follow REST principles\n"
        template = template .. "- Use Rails helpers and concerns appropriately\n\n"
    end
    
    return template
end

-- Auto-suggest files based on user's query
function M.suggest_relevant_files(query)
    local structure = M.get_rails_structure()
    local suggestions = {}
    
    query = string.lower(query)
    
    -- Model-related queries
    if string.match(query, "model") or string.match(query, "database") or string.match(query, "association") then
        for _, model in ipairs(structure.models) do
            table.insert(suggestions, model)
        end
        if structure.schema then table.insert(suggestions, structure.schema) end
    end
    
    -- Controller/routing queries
    if string.match(query, "controller") or string.match(query, "route") or string.match(query, "endpoint") then
        for _, controller in ipairs(structure.controllers) do
            table.insert(suggestions, controller)
        end
        if structure.routes then table.insert(suggestions, structure.routes) end
    end
    
    -- Test-related queries
    if string.match(query, "test") or string.match(query, "spec") or string.match(query, "rspec") then
        for _, test in ipairs(structure.tests) do
            table.insert(suggestions, test)
        end
    end
    
    -- Migration queries
    if string.match(query, "migration") or string.match(query, "migrate") then
        for _, migration in ipairs(structure.migrations) do
            table.insert(suggestions, migration)
        end
    end
    
    return suggestions
end

-- Create an autonomous agent template that includes tool suggestions
function M.create_autonomous_agent_template()
    local template = M.create_workspace_template()
    
    local agent_instructions = [[

🤖 AUTONOMOUS AGENT MODE:
You have access to these tools and should use them proactively:

• @file_search "*.rb" - Find Ruby files
• @file_search "spec/**/*_spec.rb" - Find test files  
• @read_file "path/to/file" - Read specific files
• @grep_search "ClassName" - Search for classes/methods
• @create_file - Create new files (controllers, models, etc.)
• @insert_edit_into_file - Edit existing files
• @get_changed_files - See recent git changes

SMART TOOL USAGE PATTERNS:
- When asked about code: Use @grep_search or @file_search first to locate relevant files
- When understanding features: Use @read_file on key files to understand implementations
- When building new features: Use @create_file for new components (models, controllers, views)
- When modifying code: Use @insert_edit_into_file for edits and refactoring
- When investigating issues: Use @get_changed_files to see recent changes
- When exploring codebase: Use @file_search with patterns like "*.rb", "spec/**/*", etc.

Don't wait for explicit tool instructions - use your judgment about when tools would help answer questions or complete tasks!
]]
    
    return template .. agent_instructions
end

return M
