" Mock ALE

let g:mock_ale_fail = v:false

function! ale#lsp_linter#SendRequest(buffer, server, message, callback) abort
    if g:mock_ale_fail
        throw 'Some exception from ALE'
    endif

    call a:callback({
    \   'id': 0,
    \   'jsonrpc': '2.0',
    \   'result': ccls#mock(a:message[1], a:message[2],),
    \ })
endfunction
