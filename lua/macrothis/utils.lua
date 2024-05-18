local utils = {}

local base64 = require("macrothis.base64")

utils.key_translation = function(data)
    return vim.fn.keytrans(data)
end

utils.save_data = function(opts, data)
    local content = vim.fn.json_encode(data)
    local fd = io.open(opts.datafile, "w")
    if not fd then
        vim.notify("Unable to open " .. opts.datafile .. " for write")
        return
    end

    fd:write(content)
    io.close(fd)
end

utils.read_data = function(opts)
    if vim.fn.filereadable(opts.datafile) ~= 0 then
        local fd = io.open(opts.datafile, "r")
        if fd then
            local content = fd:read("*a")
            io.close(fd)
            return vim.fn.json_decode(content)
        end
    end
    return {}
end

utils.store_register = function(opts, register, description)
    local reg = vim.fn.getreg(register)
    local regtype = vim.fn.getregtype(register)
    local data = utils.read_data(opts)
    data[description] = {}
    data[description]["value"] = base64.enc(reg)
    data[description]["type"] = regtype

    utils.save_data(opts, data)
end

utils.rename_macro = function(opts, olddescription, newdescription)
    local data = utils.read_data(opts)

    data[newdescription] = {}
    data[newdescription]["value"] = data[olddescription]["value"]
    data[newdescription]["type"] = data[olddescription]["type"]
    data[olddescription] = nil

    utils.save_data(opts, data)
end

utils.load_register = function(opts, register, description)
    local data = utils.read_data(opts)
    local content = data[description]
    vim.fn.setreg(register, base64.dec(content["value"]), content["type"])
end

utils.remove_entry = function(opts, description)
    local data = utils.read_data(opts)
    data[description] = nil
    utils.save_data(opts, data)
end

utils.run_macro = function(opts, register, description)
    utils.load_register(opts, register, description)
    vim.api.nvim_feedkeys(
        vim.api.nvim_replace_termcodes("@" .. register, true, false, true),
        "n",
        false
    )
end

utils.run_macro_on_quickfixlist = function(opts, register, description)
    utils.load_register(opts, register, description)
    vim.cmd(":silent! cfdo norm! @" .. register)
    -- Make sure we are back into normal mode after replacement
    vim.api.nvim_feedkeys(
        vim.api.nvim_replace_termcodes("<ESC>", true, false, true),
        "n",
        false
    )
end

utils.get_winopts = function(opts)
    local width = opts.editor.width
    local height = opts.editor.height

    local ui = vim.api.nvim_list_uis()[1]
    local winopts = {
        relative = "editor",
        width = width,
        height = height,
        col = (ui.width - width) / 2,
        row = (ui.height - height) / 2,
        style = opts.editor.style,
        border = opts.editor.border,
        focusable = true,
    }

    return winopts
end

utils.create_edit_register = function(register)
    local bufnr = vim.api.nvim_create_buf(false, true)

    local entrycontent = vim.fn.getreg(register)
    local entrytype = vim.fn.getregtype(register)

    entrycontent = type(entrycontent) == "string"
            and entrycontent:gsub("\n", "\\n")
        or entrycontent

    vim.api.nvim_buf_set_lines(bufnr, 0, 0, true, { entrycontent })

    vim.api.nvim_set_option_value("modifiable", true, { buf = bufnr })
    vim.api.nvim_set_option_value("buftype", "nofile", { buf = bufnr })
    vim.api.nvim_buf_set_name(bufnr, "editing " .. register)

    vim.api.nvim_create_autocmd({ "BufWinLeave" }, {
        callback = function(bufopts)
            local bufcontent =
                vim.api.nvim_buf_get_lines(bufopts.buf, 0, -1, true)

            local bbufcontent = table.concat(bufcontent, "")

            -- Re-add newlines
            local newcontent = bbufcontent:gsub("\\n", "\n")

            vim.fn.setreg(register, newcontent, entrytype)

            vim.api.nvim_set_option_value("modifiable", false, { buf = bufnr })
            vim.api.nvim_win_close(0, true)
            vim.schedule(function()
                vim.cmd("bdelete! " .. bufnr)
            end)
        end,
        buffer = bufnr,
    })

    return bufnr
end

utils.create_edit_window = function(opts, description)
    local data = utils.read_data(opts)

    local entrylabel = description
    local entrycontent = base64.dec(data[entrylabel]["value"])
    local entrytype = data[entrylabel]["type"]

    local bufnr = vim.api.nvim_create_buf(false, true)

    -- Replace newlines if found (telescope does not do multi line)
    entrycontent = type(entrycontent) == "string"
            and entrycontent:gsub("\n", "\\n")
        or entrycontent

    vim.api.nvim_buf_set_lines(bufnr, 0, 0, true, { entrycontent })

    vim.api.nvim_set_option_value("modifiable", true, { buf = bufnr })
    vim.api.nvim_set_option_value("buftype", "nofile", { buf = bufnr })
    vim.api.nvim_buf_set_name(bufnr, entrylabel)

    vim.api.nvim_create_autocmd({ "BufWinLeave" }, {
        callback = function(bufopts)
            local bufcontent =
                vim.api.nvim_buf_get_lines(bufopts.buf, 0, -1, true)

            local bbufcontent = table.concat(bufcontent, "")

            -- Re-add newlines
            local newcontent = bbufcontent:gsub("\\n", "\n")

            vim.fn.setreg(opts.run_register, newcontent, entrytype)
            utils.store_register(opts, opts.run_register, entrylabel)

            vim.api.nvim_set_option_value("modifiable", false, { buf = bufnr })
            vim.api.nvim_win_close(0, true)
            vim.schedule(function()
                vim.cmd("bdelete! " .. bufnr)
            end)
        end,
        buffer = bufnr,
    })

    return bufnr
end

return utils
