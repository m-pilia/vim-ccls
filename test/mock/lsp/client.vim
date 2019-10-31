" Mock vim-lsp

function! lsp#client#is_error(response) abort
    let l:vt = type(a:response)
    if l:vt == type('')
        return len(a:response) > 0
    elseif l:vt == type({})
        return has_key(a:response, 'error')
    endif
    return 0
endfunction
