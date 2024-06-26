local has_telescope, telescope = pcall(require, "telescope")
if not has_telescope then
    error("macrothis's telescope extention needs nvim-telescope/telescope.nvim")
end

local finders = require("telescope.finders")
local action_state = require("telescope.actions.state")
local actions = require("telescope.actions")
local sorters = require("telescope.sorters")
local pickers = require("telescope.pickers")
local entry_display = require("telescope.pickers.entry_display")
local macrothis = require("macrothis")
local utils = require("macrothis.utils")

-- Forward declare
local pickerfunc

--- Default telescope options
---@eval return MiniDoc.afterlines_to_code(MiniDoc.current.eval_section)
local default_telescope = {
    mappings = {
        load = "<CR>",
        save = "<C-s>",
        delete = "<C-d>",
        run = "<C-r>",
        rename = "<C-n>",
        edit = "<C-e>",
        quickfix = "<C-q>",
        register = "<C-x>",
        copy_macro = "<C-c>",
        help = "<C-h>",
    },
    sorter = sorters.get_generic_fuzzy_sorter,
    items_display = {
        separator = " ",
        hl_chars = { ["["] = "TelescopeBorder", ["]"] = "TelescopeBorder" },
        items = {
            { width = 50 },
            { remaining = true },
        },
    },
    register_display = {
        separator = " ",
        hl_chars = { ["["] = "TelescopeBorder", ["]"] = "TelescopeBorder" },
        items = {
            { width = 4 },
            { remaining = true },
        },
    },
}
--minidoc_afterlines_end

local setup = function(ext_config, _)
    macrothis.telescope_config =
        vim.tbl_deep_extend("force", default_telescope, ext_config or {})
end

local generate_new_finder_items = function(_)
    local displayer =
        entry_display.create(macrothis.telescope_config.items_display)

    local function make_display(entry)
        local content = entry.value.value
        content = type(content) == "string" and content:gsub("\n", "\\n")
            or content

        return displayer({
            { "[" .. entry.value.label .. "]", "TelescopeResultsNumber" },
            content,
        })
    end

    return finders.new_table({
        results = macrothis.generate_menu_items(),
        entry_maker = function(entry)
            local content = entry.value
            content = type(content) == "string" and content:gsub("\n", "\\n")
                or content

            local table = {
                value = entry,
                ordinal = entry.label,
                display = make_display,
                content = content,
            }
            return table
        end,
    })
end

local generate_new_finder_registers = function()
    local displayer =
        entry_display.create(macrothis.telescope_config.register_display)

    local function make_display(entry)
        local content = entry.value.value
        content = type(content) == "string" and content:gsub("\n", "\\n")
            or content

        return displayer({
            { "[" .. entry.value.label .. "]", "TelescopeResultsNumber" },
            content,
        })
    end
    return finders.new_table({
        results = macrothis.generate_register_items(),

        entry_maker = function(entry)
            local content = entry.value
            content = type(content) == "string" and content:gsub("\n", "\\n")
                or content

            local table = {
                value = entry,
                ordinal = entry.label,
                display = make_display,
                content = content,
            }
            return table
        end,
    })
end

local load_macro = function(_)
    local selected_macro = action_state.get_selected_entry()

    if macrothis.opts.default_register ~= "" then
        utils.load_register(
            macrothis.opts,
            macrothis.opts.default_register,
            selected_macro.value.label
        )

        actions.close(vim.api.nvim_get_current_buf())
        return
    end

    local opts = macrothis.telescope_config.opts
    opts["ngram_len"] = 1 -- make sure we sort based on register name which is only one char

    pickers
        .new({}, {
            prompt_title = "Load into register",
            finder = generate_new_finder_registers(),
            sorter = macrothis.telescope_config.sorter(opts),
            attach_mappings = function(_, map)
                map(
                    "i",
                    macrothis.telescope_config.mappings.load,
                    function(newprompt_bufnr)
                        local selected_register =
                            action_state.get_selected_entry()
                        utils.load_register(
                            macrothis.opts,
                            selected_register.value.label,
                            selected_macro.value.label
                        )
                        actions.close(newprompt_bufnr)
                    end
                )
                return true
            end,
        })
        :find()
end

local delete_macro = function(prompt_bufnr)
    -- use input while we wait for vim.ui.confirm
    vim.ui.input(
        { prompt = "Confirm deletion? [y/n]: " },
        function(confirmation)
            if
                string.len(confirmation) == 0
                or string.sub(string.lower(confirmation), 0, 1) ~= "y"
            then
                print("cancelled")
                return
            end

            local current_picker = action_state.get_current_picker(prompt_bufnr)
            current_picker:delete_selection(function(selection)
                utils.remove_entry(macrothis.opts, selection.value.label)
            end)
        end
    )
end

local save_macro = function(_)
    local opts = macrothis.telescope_config.opts
    opts["ngram_len"] = 1 -- make sure we sort based on register name which is only one char
    pickers
        .new({}, {
            prompt_title = "Choose register",
            finder = generate_new_finder_registers(),
            sorter = macrothis.telescope_config.sorter(opts),
            attach_mappings = function(_, map)
                map(
                    "i",
                    macrothis.telescope_config.mappings.load,
                    function(newprompt_bufnr)
                        local selected_register =
                            action_state.get_selected_entry()
                        vim.ui.input({
                            prompt = "Enter description: ",
                        }, function(description)
                            if description then
                                utils.store_register(
                                    macrothis.opts,
                                    selected_register.value.label,
                                    description
                                )
                                actions.close(newprompt_bufnr)
                            end
                        end)
                    end
                )
                return true
            end,
        })
        :find()
end

local run_macro = function(prompt_bufnr)
    local selected_macro = action_state.get_selected_entry()

    actions.close(prompt_bufnr)

    utils.run_macro(
        macrothis.opts,
        macrothis.opts.run_register,
        selected_macro.value.label
    )
end

local run_macro_on_quickfixlist = function(prompt_bufnr)
    local selected_macro = action_state.get_selected_entry()

    actions.close(prompt_bufnr)

    utils.run_macro_on_quickfixlist(
        macrothis.opts,
        macrothis.opts.run_register,
        selected_macro.value.label
    )
end

local rename_macro = function(prompt_bufnr)
    local selected_register = action_state.get_selected_entry()

    -- TODO would be nice if we didn't close the menu and just updated telescope dynamically
    vim.ui.input({
        prompt = "New description: ",
        default = selected_register.value.label,
    }, function(newdescription)
        if newdescription then
            utils.rename_macro(
                macrothis.opts,
                selected_register.value.label,
                newdescription
            )
            actions.close(prompt_bufnr)
        end
    end)
end

local edit_macro = function(prompt_bufnr)
    local selected_item = action_state.get_selected_entry()

    local bufnr =
        utils.create_edit_window(macrothis.opts, selected_item.value.label)

    actions.close(prompt_bufnr)

    local winopts = utils.get_winopts(macrothis.opts)
    vim.api.nvim_open_win(bufnr, true, winopts)
    vim.api.nvim_win_set_buf(0, bufnr)
end

local edit_register = function(_)
    local opts = macrothis.telescope_config.opts
    opts["ngram_len"] = 1 -- make sure we sort based on register name which is only one char

    pickers
        .new({}, {
            prompt_title = "Edit register",
            finder = generate_new_finder_registers(),
            sorter = macrothis.telescope_config.sorter(opts),
            attach_mappings = function(_, map)
                map(
                    "i",
                    macrothis.telescope_config.mappings.load,
                    function(prompt_bufnr)
                        local selected_register =
                            action_state.get_selected_entry()

                        local bufnr = utils.create_edit_register(
                            selected_register.value.label
                        )

                        actions.close(prompt_bufnr)

                        local winopts = utils.get_winopts(macrothis.opts)
                        vim.api.nvim_open_win(bufnr, true, winopts)
                        vim.api.nvim_win_set_buf(0, bufnr)

                        vim.api.nvim_feedkeys(
                            vim.api.nvim_replace_termcodes(
                                "<ESC>",
                                true,
                                false,
                                true
                            ),
                            "n",
                            false
                        )
                    end
                )
                map("i", "<C-c>", function(prompt_bufnr)
                    local selected_register = action_state.get_selected_entry()
                    local printable =
                        utils.key_translation(selected_register.value.value)
                    vim.fn.setreg(macrothis.opts.clipboard_register, printable)
                    vim.notify("Copied to clipboard")
                    actions.close(prompt_bufnr)
                end)
                return true
            end,
        })
        :find()
end

local copy_printable = function(prompt_bufnr)
    local selected_macro = action_state.get_selected_entry()
    local printable = utils.key_translation(selected_macro.value.value)
    vim.fn.setreg(macrothis.opts.clipboard_register, printable)
    vim.notify("Copied to clipboard")
    actions.close(prompt_bufnr)
end

local help = function(prompt_bufnr)
    actions.close(prompt_bufnr)

    local opts = utils.get_winopts(macrothis.opts)
    local entries = {}
    local translation = {
        edit = "Edit macro",
        load = "Load macro",
        save = "Save a register as a macro",
        delete = "Delete macro",
        run = "Run macro",
        rename = "Rename macro",
        quickfix = "Run macro on quickfix list",
        copy_macro = "Copy a macro to a new name",
        register = "Edit a register",
    }

    table.insert(entries, "Macrothis help:")
    table.insert(entries, "")

    local width = 20
    for key, value in pairs(macrothis.telescope_config.mappings) do
        local tkey = translation[key] or key

        local entry = value .. ": " .. tkey
        table.insert(entries, entry)

        if string.len(entry) > width then
            width = string.len(entry)
        end
    end

    local bufnr = vim.api.nvim_create_buf(false, false)

    local options = { buf = bufnr }

    vim.api.nvim_set_option_value("buftype", "nofile", options)
    vim.api.nvim_set_option_value("filetype", "macrothishelp", options)
    vim.api.nvim_set_option_value("bufhidden", "wipe", options)
    vim.api.nvim_set_option_value("swapfile", false, options)

    vim.api.nvim_buf_set_lines(bufnr, 0, -1, true, entries)

    vim.api.nvim_set_option_value("modifiable", false, options)

    opts.style = "minimal"
    opts.zindex = 200
    opts.width = width + 5
    opts.height = #entries
    local win = vim.api.nvim_open_win(bufnr, true, opts)
    vim.api.nvim_win_set_buf(win, bufnr)

    -- Return to picker
    vim.api.nvim_create_autocmd({ "BufWinLeave" }, {
        callback = function(_)
            vim.schedule(function()
                pickerfunc(macrothis.telescope_config.opts)
            end)
        end,
        buffer = bufnr,
    })
end

local runpicker = function(opts)
    local picker = pickers.new(opts, {
        prompt_title = "Macro this",
        finder = generate_new_finder_items(opts),
        sorter = macrothis.telescope_config.sorter(opts),
        attach_mappings = function(_, map)
            map("i", macrothis.telescope_config.mappings.load, load_macro)
            map("i", macrothis.telescope_config.mappings.delete, delete_macro)
            map("i", macrothis.telescope_config.mappings.save, save_macro)
            map("i", macrothis.telescope_config.mappings.run, run_macro)
            map(
                "i",
                macrothis.telescope_config.mappings.quickfix,
                run_macro_on_quickfixlist
            )
            map("i", macrothis.telescope_config.mappings.rename, rename_macro)
            map("i", macrothis.telescope_config.mappings.edit, edit_macro)
            map(
                "i",
                macrothis.telescope_config.mappings.register,
                edit_register
            )
            map(
                "i",
                macrothis.telescope_config.mappings.copy_macro,
                copy_printable
            )
            map("i", macrothis.telescope_config.mappings.help, help)
            return true
        end,
    })

    picker:find()
end
pickerfunc = runpicker

local run = function(opts)
    macrothis.telescope_config.opts = opts
    pickerfunc(opts)
end

return telescope.register_extension({
    setup = setup,
    exports = {
        macrothis = run,
    },
})
