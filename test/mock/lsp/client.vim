" Mock vim-lsp

function! lsp#client#is_error(response) abort
    return v:false
endfunction
