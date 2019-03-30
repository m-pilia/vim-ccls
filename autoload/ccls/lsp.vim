function! s:handle_response(handler, data) abort
    if lsp#client#is_error(a:data.response)
        echoerr 'LSP error'
        return
    endif
    call a:handler(a:data.response.result)
endfunction

function! ccls#lsp#request(method, params, handler) abort
    let l:available_servers = lsp#get_server_names()
    if len(l:available_servers) == 0 || count(l:available_servers, 'ccls') == 0
        echoerr 'ccls language server unvailable'
        return
    endif

    let l:request = {
    \   'method': '$ccls/' . a:method,
    \   'params': a:params,
    \   'on_notification': function('s:handle_response', [a:handler]),
    \ }

    call lsp#send_request('ccls', l:request)
endfunction
