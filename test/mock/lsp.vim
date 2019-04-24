" Mock vim-lsp

function! lsp#get_server_names() abort
    return ['ccls']
endfunction

function! lsp#send_request(server, request) abort
    call a:request.on_notification({
    \   'response': {
    \       'result': ccls#mock(a:request.method, a:request.params),
    \   },
    \ })
endfunction
