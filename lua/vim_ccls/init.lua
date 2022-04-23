local function warning(message)
    vim.api.nvim_call_function("ccls#util#warning", {"nvim-lspconfig error: " .. message})
end

local function get_ccls(bufnr)
    clients = vim.lsp.buf_get_clients(bufnr)
    for _, v in pairs(clients) do
        if v["name"] == "ccls" then
            return v
        end
    end
    return nil
end

local function handle_response(err, call_id, result)
    if err then
        warning("no result from ccls")
    else
        vim.api.nvim_call_function("ccls#lsp#nvim_lspconfig#callback", {call_id, result})
    end
end

local function get_handler(call_id)
    version = vim.version()

    if version['major'] <= 0 and version['minor'] <= 5 and version['patch'] <= 0 then
        handler = function(err, method, result, client_id) handle_response(err, call_id, result) end
    else
        handler = function(err, result, ctx, config) handle_response(err, call_id, result) end
    end

    return handler
end

local function request(bufnr, method, params, call_id)
    ccls = get_ccls(bufnr)

    if ccls == nil then
        warning("ccls unavailable for buffer " .. bufnr)
        return
    end

    status = ccls.request(method, params, get_handler(call_id))

    if not status then
        warning("failed ccls request")
    end
end

return {
    request = request,
}
