scriptencoding utf-8

function! yggdrasil#tree#get_node_id_under_cursor() dict abort
    let l:id = str2nr(matchstr(getline('.'), '\v\[@<=\d+\]@='))
    return l:self.root.find(l:id)
endfunction

function! yggdrasil#tree#set_collapsed_under_cursor(collapsed, recursive) dict abort
    let l:node = l:self.get_node_id_under_cursor()
    call l:node.set_collapsed(a:collapsed, a:recursive)
    call l:self.render()
endfunction

function! yggdrasil#tree#insert(label, callback, lazy_open, ...) dict abort
    let l:self.maxid += 1
    let l:parent = l:self.root == {} || a:0 == 0 ? {} : l:self.root.find(a:1)
    let l:node = yggdrasil#node#new(l:self.maxid, a:label, l:parent, a:callback, a:lazy_open)

    if l:parent == {}
        if l:self.root != {}
            call add(l:node['children'], l:self.root)
        endif
        let l:self.root = l:node
    else
        call add(l:parent['children'], l:node)
    endif

    return l:node
endfunction

function! yggdrasil#tree#render() dict abort
    let l:cursor = getpos('.')
    let l:text = l:self.root.render(0)

    setlocal modifiable
    silent 1,$delete _
    silent 0put=l:text
    setlocal nomodifiable

    call setpos('.', l:cursor)
endf

function! yggdrasil#tree#new(size, position, orientation) abort
    let l:position = a:position =~# '\v^t|l' ? 'topleft' : 'botright'
    let l:orientation = a:orientation =~# '^v' ? 'vnew' : 'new'
    exec l:position . ' ' . a:size . l:orientation

    let b:yggdrasil_tree = {
    \ 'bufnr': bufnr('.'),
    \ 'maxid': -1,
    \ 'root': {},
    \ 'insert': function('yggdrasil#tree#insert'),
    \ 'set_collapsed_under_cursor': function('yggdrasil#tree#set_collapsed_under_cursor'),
    \ 'get_node_id_under_cursor': function('yggdrasil#tree#get_node_id_under_cursor'),
    \ 'render': function('yggdrasil#tree#render'),
    \ }

    setlocal filetype=yggdrasil
endfunction
