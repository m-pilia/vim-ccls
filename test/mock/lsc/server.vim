" Mock vim-lsc
function! lsc#server#userCall(method, params, callback) abort
    call a:callback(ccls#mock(a:method, a:params))
endfunction
