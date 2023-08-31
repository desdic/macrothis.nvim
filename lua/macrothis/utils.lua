local utils = {}

local base64 = require("macrothis.base64")
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
    vim.cmd(":cfdo norm! @" .. register)
    -- Make sure we are back into normal mode after replacement
    vim.api.nvim_feedkeys(
        vim.api.nvim_replace_termcodes("<ESC>", true, false, true),
        "n",
        false
    )
end

return utils
