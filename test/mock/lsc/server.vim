" Mock vim-lsc
function! lsc#server#call(filetype, method, params, callback) abort
    if index(['c', 'cpp'], a:filetype) < 0
        echoerr 'Unexpected filetype "' . a:filetype . '"'
        return
    endif
    call a:callback(ccls#mock(a:method, a:params))
endfunction
