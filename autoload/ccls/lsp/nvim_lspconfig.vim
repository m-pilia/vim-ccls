" Currently it is not possible to call a VimL funcref from Lua. This
" library allows to register callback funcrefs and later call them
" through a public function, that is accessible from Lua.

let s:call_id = 0
let s:callbacks = {}

" Register a callback and return a call id
function! ccls#lsp#nvim_lspconfig#register(funcref) abort
    let s:call_id += 1
    let s:callbacks[s:call_id] = a:funcref
    return s:call_id
endfunction

" Call a registered callback, identified by {call_id}, with given {data}
function! ccls#lsp#nvim_lspconfig#callback(call_id, data) abort
    if has_key(s:callbacks, a:call_id)
        call call(s:callbacks[a:call_id], [a:data])
        call remove(s:callbacks, a:call_id)
    endif
endfunction

