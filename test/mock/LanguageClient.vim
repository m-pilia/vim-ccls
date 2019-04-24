" Mock LanguageClient-neovim
function! LanguageClient#Call(method, params, callback) abort
    call a:callback({
    \   'id': 0,
    \   'jsonrpc': '2.0',
    \   'result': ccls#mock(a:method, a:params),
    \ })
endfunction
