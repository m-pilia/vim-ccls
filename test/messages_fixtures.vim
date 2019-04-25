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

function! s:assert_inner_nodes(expected_label)
    AssertEqual 2, len(b:yggdrasil_tree.root.children[1].children)
    AssertEqual a:expected_label . '_3', b:yggdrasil_tree.root.children[1].children[0].label
    AssertEqual a:expected_label . '_4', b:yggdrasil_tree.root.children[1].children[1].label
endfunction

function! Test_hierarchy(function, expected_method, expected_label) abort
    edit test/example.cpp

    call a:function()

    AssertEqual &filetype, 'yggdrasil'
    AssertEqual a:expected_method, b:yggdrasil_tree.method
    AssertEqual 'node_0', b:yggdrasil_tree.root.label

    if g:ccls_levels >= 1
        AssertEqual 2, len(b:yggdrasil_tree.root.children)
        AssertNotEqual type({->0}), type(b:yggdrasil_tree.root.lazy_open)
        AssertEqual a:expected_label . '_1', b:yggdrasil_tree.root.children[0].label
        AssertEqual a:expected_label . '_2', b:yggdrasil_tree.root.children[1].label
        AssertEqual 0, len(b:yggdrasil_tree.root.children[0].children)

        if g:ccls_levels < 2
            AssertEqual 0, len(b:yggdrasil_tree.root.children[1].children)
            AssertEqual type({->0}), type(b:yggdrasil_tree.root.children[1].lazy_open)
        else
            AssertNotEqual type({->0}), type(b:yggdrasil_tree.root.children[1].lazy_open)
            call s:assert_inner_nodes(a:expected_label)
        endif
    endif
endfunction

function! Test_lazy_open(expected_label) abort
    let l:collapsed = 0
    let l:recursive = 0

    " Expand root node
    call b:yggdrasil_tree.set_collapsed_under_cursor(l:collapsed, l:recursive)

    " Move over the collapsed node with two children (node_2)
    call search(a:expected_label . '_2')

    AssertEqual b:yggdrasil_tree.root.children[1].id, b:yggdrasil_tree.get_node_id_under_cursor().id,

    " Expand lazily the inner node with two children (node_2)
    call b:yggdrasil_tree.set_collapsed_under_cursor(l:collapsed, l:recursive)

    AssertNotEqual type({->0}), type(b:yggdrasil_tree.root.children[1].lazy_open),

    call s:assert_inner_nodes(a:expected_label)
endfunction
