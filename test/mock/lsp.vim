" Mock vim-lsp

source test/mock/lsp/client.vim

let g:mock_lsp_server_names = ['ccls']

function! lsp#get_server_names() abort
    return g:mock_lsp_server_names
endfunction

function! lsp#send_request(server, request) abort
    call a:request.on_notification({
    \   'response': {
    \       'result': ccls#mock(a:request.method, a:request.params),
    \   },
    \ })
endfunction
