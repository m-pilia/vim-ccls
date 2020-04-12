function! Test_jump_to(jump_to) abort
    let l:row = 5
    let l:col = 6
    let l:node = 0 " unused

    new

    call a:jump_to('test/example.cpp', l:row, l:col)

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

function! Test_hierarchy(function, expected_method, expected_label, expected_float) abort
    edit test/example.cpp

    call a:function()

    " Open all nodes
    let l:last_line = 0
    let l:line = line('.')
    while l:line != l:last_line
        let l:last_line = line('.')
        normal! j
        call b:yggdrasil_tree.set_collapsed_under_cursor(v:false)
        let l:line = line('.')
    endwhile

    AssertEqual 'yggdrasil', &filetype
    AssertEqual a:expected_method, b:yggdrasil_tree.provider.method
    AssertEqual a:expected_label . '_0', b:yggdrasil_tree.root.tree_item.label

    AssertEqual 2, len(b:yggdrasil_tree.root.children)
    AssertNotEqual type({->0}), type(b:yggdrasil_tree.root.lazy_open)
    AssertEqual a:expected_label . '_1', b:yggdrasil_tree.root.children[0].tree_item.label
    AssertEqual a:expected_label . '_2', b:yggdrasil_tree.root.children[1].tree_item.label

    AssertEqual 2, len(b:yggdrasil_tree.root.children[1].children)
    AssertEqual a:expected_label . '_3', b:yggdrasil_tree.root.children[1].children[0].tree_item.label
    AssertEqual a:expected_label . '_4', b:yggdrasil_tree.root.children[1].children[1].tree_item.label

    if exists('*nvim_open_win') && a:expected_float
        let l:props = nvim_win_get_config(0)
        AssertEqual 'win', l:props['relative']
        AssertEqual g:ccls_float_width, l:props['width']
        AssertEqual g:ccls_float_height, l:props['height']
        close " close floating window
    endif
endfunction
