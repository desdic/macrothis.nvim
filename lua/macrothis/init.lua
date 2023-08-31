--- Macrothis.nvim is a plugin for saving and loading registers/macros
---
---@usage Using Lazy plugin manager
--- {
---     "desdic/macrothis.nvim",
---     opts = {},
---     keys = {
---         {
---             "<Leader>kks",
---             function()
---                 require('macrothis').save()
---             end,
---             desc = "save register/macro"
---         },
---         {
---             "<Leader>kkl",
---             function()
---                 require('macrothis').load()
---             end,
---             desc = "load register/macro"
---         },
---         {
---             "<Leader>kkd",
---             function()
---                 require('macrothis').delete()
---             end,
---             desc = "delete register/macro"
---         },
---         {
---             "<Leader>kkq",
---             function()
---                 require('macrothis').quickfix()
---             end,
---             desc = "run on quickfix list"
---         },
---         {
---             "<Leader>kkr",
---             function()
---                 require('macrothis').run()
---             end,
---             desc = "run macro"
---         }
---     }
--- },
---
---@tag macrothis.nvim

local macrothis = {}

local utils = require("macrothis.utils")
local base64 = require("macrothis.base64")

macrothis.generate_menu_items = function()
    local menuelem = {}

    local content = utils.read_data(macrothis.opts)
    for key, value in pairs(content) do
        local entry = {
            label = key,
            value = base64.dec(value["value"]),
            type = value["type"],
        }

        table.insert(menuelem, entry)
    end

    return menuelem
end

macrothis.generate_register_items = function()
    local items = {}

    local registers = macrothis.opts.registers

    for _, reg in ipairs(registers) do
        local curreg = vim.fn.getreg(reg)
        local curregtype = vim.fn.getregtype(reg)

        local entry = {
            label = reg,
            value = curreg,
            type = curregtype,
        }

        table.insert(items, entry)
    end

    return items
end

--- Save a macro/register
---
---@usage `require('macrothis').save()`
macrothis.save = function()
    local registers = macrothis.generate_register_items()
    vim.ui.select(registers, {
        prompt = "Save which register?",
        format_item = function(item)
            return ("%s: %s: %s"):format(item.label, item.value, item.type)
        end,
    }, function(register, _)
        if register then
            vim.ui.input(
                { prompt = "Enter description: " },
                function(description)
                    print(vim.inspect(register))
                    utils.store_register(
                        macrothis.opts,
                        register.label,
                        description
                    )
                    macrothis.opts.last_used = description
                end
            )
        end
    end)
end

--- Load a macro/register
---
---@usage `require('macrothis').load()`
macrothis.load = function()
    local menuelem = macrothis.generate_menu_items()

    vim.ui.select(menuelem, {
        prompt = "Load macro",
        format_item = function(item)
            return ("%s: %s"):format(item.label, item.value)
        end,
    }, function(description, _)
        if description then
            local registers = macrothis.generate_register_items()
            vim.ui.select(registers, {
                prompt = "Load to which register?",
                format_item = function(item)
                    return ("%s: %s: %s"):format(
                        item.label,
                        item.value,
                        item.type
                    )
                end,
            }, function(register, _)
                if register then
                    utils.load_register(
                        macrothis.opts,
                        register.label,
                        description.label
                    )
                    macrothis.opts.last_used = description.label
                end
            end)
        end
    end)
end

--- Delete a macro/register
---
---@usage `require('macrothis').delete()`
macrothis.delete = function()
    local menuelem = macrothis.generate_menu_items()

    vim.ui.select(menuelem, {
        prompt = "Delete macro",
        format_item = function(item)
            return ("%s: %s"):format(item.label, item.value)
        end,
    }, function(description, _)
        if description then
            utils.remove_entry(macrothis.opts, description.label)
            if macrothis.opts.last_used == description.label then
                macrothis.opts.last_used = ""
            end
        end
    end)
end

--- Run macro
---
---@usage `require('macrothis').run()`
macrothis.run = function()
    local menuelem = macrothis.generate_menu_items()

    vim.ui.select(menuelem, {
        prompt = "Run on quickfix list",
        format_item = function(item)
            return ("%s: %s"):format(item.label, item.value)
        end,
    }, function(description, _)
        if description then
            utils.run_macro(
                macrothis.opts,
                macrothis.opts.run_register,
                description.label
            )
            macrothis.opts.last_used = description.label
        end
    end)
end

--- Run macro on all in quickfix list
---
---@usage `require('macrothis').quickfix()`
macrothis.quickfix = function()
    local menuelem = macrothis.generate_menu_items()

    vim.ui.select(menuelem, {
        prompt = "Run on quickfix list",
        format_item = function(item)
            return ("%s: %s"):format(item.label, item.value)
        end,
    }, function(description, _)
        if description then
            utils.run_macro_on_quickfixlist(
                macrothis.opts,
                macrothis.opts.run_register,
                description.label
            )
            macrothis.opts.last_used = description.label
        end
    end)
end

local generate_register_list = function()
    local registers_table = { '"', "-", "#", "=", "/", "*", "+", ":", ".", "%" }

    -- named
    for i = 0, 9 do
        table.insert(registers_table, tostring(i))
    end

    -- alphabetical
    for i = 97, 122 do
        table.insert(registers_table, string.char(i))
    end

    return registers_table
end

--- Default options
---@eval return MiniDoc.afterlines_to_code(MiniDoc.current.eval_section)
local default = {
    datafile = vim.fn.stdpath("data") .. "/macrothis.json",
    registers = generate_register_list(),
    run_register = "z", -- content of register z is replaced when running a macro
}
--minidoc_afterlines_end

macrothis.setup = function(opts)
    macrothis.opts = vim.tbl_deep_extend("force", default, opts or {})
end

return macrothis
