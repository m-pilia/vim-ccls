" Mock LanguageClient-neovim
function! LanguageClient#Call(method, params, callback) abort
    if index(['c', 'cpp'], &filetype) < 0
        throw 'LanguageClient mock: Unsupported filetype "' . &filetype . '"'
    endif

    call a:callback({
    \   'id': 0,
    \   'jsonrpc': '2.0',
    \   'result': ccls#mock(a:method, a:params),
    \ })
endfunction
