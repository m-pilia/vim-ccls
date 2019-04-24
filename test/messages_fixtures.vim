function! Test_jump_to(jump_to) abort
    let l:row = 5
    let l:col = 6
    let l:node = 0 " unused

    new

    call a:jump_to('test/example.cpp', l:row, l:col, l:node)

    let l:position = getcurpos()

    if has('win32')
        Assert match(expand('%:p'), 'test\example.cpp$') >= 0
    else
        Assert match(expand('%:p'), 'test/example.cpp$') >= 0
    endif

    AssertEqual l:row, l:position[1]
    AssertEqual l:col, l:position[2]
endfunction

function! Test_locations(function) abort
    let l:lines = [
    \   '    int x;',
    \   '    float y;',
    \   '    printf("Hello, World!\n");',
    \ ]
    let l:row = 5
    let l:col = 6

    edit test/example.cpp
    call cursor(l:row, l:col)

    call a:function()

    let l:qfl = getqflist()

    AssertEqual 3, len(l:qfl)
    for l:i in range(len(l:qfl))
        AssertEqual l:row + l:i, l:qfl[l:i].lnum
        AssertEqual l:col, l:qfl[l:i].col
        AssertEqual l:lines[l:i], l:qfl[l:i].text
    endfor
endfunction

function! Test_hierarchy(function, expected_method, expected_label) abort
    edit test/example.cpp

    call a:function()

    AssertEqual &filetype, 'yggdrasil'
    AssertEqual a:expected_method, b:yggdrasil_tree.method
    AssertEqual 'node_0', b:yggdrasil_tree.root.label

    if g:lsp_ccls_levels >= 1
        AssertEqual 2, len(b:yggdrasil_tree.root.children)
        AssertNotEqual type({->0}), type(b:yggdrasil_tree.root.lazy_open)
        AssertEqual a:expected_label . '_1', b:yggdrasil_tree.root.children[0].label
        AssertEqual a:expected_label . '_2', b:yggdrasil_tree.root.children[1].label
        AssertEqual 0, len(b:yggdrasil_tree.root.children[0].children)

        if g:lsp_ccls_levels < 2
            AssertEqual 0, len(b:yggdrasil_tree.root.children[1].children)
            AssertEqual type({->0}), type(b:yggdrasil_tree.root.children[1].lazy_open)
        else
            AssertEqual 2, len(b:yggdrasil_tree.root.children[1].children)
            AssertNotEqual type({->0}), type(b:yggdrasil_tree.root.children[1].lazy_open)
            AssertEqual a:expected_label . '_3', b:yggdrasil_tree.root.children[1].children[0].label
            AssertEqual a:expected_label . '_4', b:yggdrasil_tree.root.children[1].children[1].label
        endif
    endif
endfunction
