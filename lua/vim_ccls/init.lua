local function warning(message)
    vim.api.nvim_call_function("ccls#util#warning", {"nvim-lspconfig error: " .. message})
end

local function get_ccls(bufnr)
    clients = vim.lsp.buf_get_clients(bufnr)
    for _, v in ipairs(clients) do
        if v["name"] == "ccls" then
            return v
        end
    end
    return nil
end

local function request(bufnr, method, params, call_id)
    ccls = get_ccls(bufnr)

    if ccls == nil then
        warning("ccls unavailable for buffer " .. bufnr)
        return
    end

    status = ccls.request(method, params, function(_, method, result, client_id)
        if not result then
            warning("no result from ccls")
        else
            vim.api.nvim_call_function("ccls#lsp#nvim_lspconfig#callback", {call_id, result})
        end
    end)

    if not status then
        warning("failed ccls request")
    end
end

return {
    request = request,
}
