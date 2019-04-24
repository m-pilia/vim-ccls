" Mock coc.nvim
function! CocRequestAsync(server, method, params, callback) abort
    if a:server !=# 'ccls'
        echoerr 'Unsupported server "' . a:server . '"'
        return
    endif

    let l:error = v:null
    call a:callback(l:error, ccls#mock(a:method, a:params))
endfunction
