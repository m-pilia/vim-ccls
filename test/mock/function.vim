" Not a dict function, so the mock can be used within other dictionaries
function! s:call_mock(mock, ...) abort
    let a:mock.count += 1
    call add(a:mock.args, a:000)
endfunction

" Get a function mock object
function! NewFunctionMock() abort
    let l:mock = {
    \   'count': 0,
    \   'args': [],
    \ }
    let l:mock.function = function('s:call_mock', [l:mock])
    return l:mock
endfunction
