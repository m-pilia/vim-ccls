source test/mock/function.vim
let s:mock = NewFunctionMock()

function! ccls#lsp#get_mock() abort
    return s:mock
endfunction

function! ccls#lsp#request(...) abort
    call call(s:mock.function, a:000)
endfunction
