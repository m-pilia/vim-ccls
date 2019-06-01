" Mock ALE

function! ale#lsp_linter#SendRequest(buffer, server, message, callback) abort
    call a:callback({
    \   'id': 0,
    \   'jsonrpc': '2.0',
    \   'result': ccls#mock(a:message[1], a:message[2],),
    \ })
endfunction
