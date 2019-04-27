let s:project_root = '/testplugin/test'

function! ale#handlers#ccls#GetProjectRoot(bufnr) abort
    return s:project_root
endfunction

