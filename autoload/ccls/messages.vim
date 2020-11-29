" Convert a path to an uri
function! s:path2uri(path) abort
    let l:path = substitute(a:path, '\', '/', 'g')

    let l:prefix = matchstr(l:path, '\v(^\w+::|^\w+://)')
    if len(l:prefix) < 1
        let l:prefix = 'file://'
    endif

    let l:volume_end = has('win32') ? matchstrpos(l:path, '\c[A-Z]:')[2] : 0
    if l:volume_end < 0
        let l:volume_end = 0
    endif

    let l:uri = l:prefix . strpart(l:path, 0, l:volume_end)
    for l:index in range(l:volume_end, len(l:path) - 1)
        if l:path[l:index] =~# '^[a-zA-Z0-9_.~/-]$'
            let l:uri .= l:path[l:index]
        else
            let l:uri .= printf('%%%02X', char2nr(l:path[l:index]))
        endif
    endfor

    return l:uri
endfunction

" Convert an uri to a path
function! s:uri2path(uri) abort
    let l:path = substitute(a:uri, '^file://', '', '')
    let l:path = substitute(l:path, '[?#].*', '', '')
    let l:path = substitute(l:path,
    \                       '%\(\x\x\)',
    \                       '\=printf("%c", str2nr(submatch(1), 16))',
    \                       'g')
    if has('win32')
        let l:path = substitute(l:path, '/', '\\', 'g')
    endif
    return l:path
endfunction

" Get the text document identifier for the current buffer
function! s:text_document_identifier() abort
    return {'uri': s:path2uri(expand('%:p'))}
endfunction

" Get the position under the cursor
function! s:position() abort
    return {'line': line('.') - 1, 'character': col('.') - 1}
endfunction

" Jump to a specified position in a given file
function! s:jump_to(file, line, column) abort
    let l:yggdrasil_bufno = bufnr('%')
    silent execute "normal! \<c-w>\<c-p>"
    if g:ccls_close_on_jump
        silent execute 'bd' . l:yggdrasil_bufno
    endif
    let l:buffer = bufnr(a:file)
    let l:command = l:buffer !=# -1 ? 'b ' . l:buffer : 'edit ' . a:file
    silent execute l:command . ' | call cursor(' . a:line . ',' . a:column . ')'
    call nvim_win_close(s:float_id, v:true)
    let s:base_split_window = 0
    let s:preview_split_window = 0
    let s:yggdrasil_window = 0
endfunction

let s:base_split_window = 0
let s:preview_split_window = 0
let s:yggdrasil_window = 0

" Jump to a specified position in a given file
function! s:preview_to(file, line, column) abort
    if s:yggdrasil_window == 0
      let s:yggdrasil_window = nvim_get_current_win()
    endif
    if s:base_split_window == 0
      silent execute "normal! \<c-w>\<c-p>"
      let s:base_split_window = nvim_get_current_win()
      call nvim_set_current_win(s:yggdrasil_window)
    endif
    if s:preview_split_window == 0
      call nvim_set_current_win(s:base_split_window)
      silent execute "botright vs"
      let s:preview_split_window = nvim_get_current_win()
      call nvim_set_current_win(s:yggdrasil_window)
    endif
    call nvim_set_current_win(s:preview_split_window)
    let l:yggdrasil_bufno = bufnr('%')
    let l:buffer = bufnr(a:file)
    let l:command = l:buffer !=# -1 ? 'b ' . l:buffer : 'edit ' . a:file
    silent execute l:command . ' | call cursor(' . a:line . ',' . a:column . ')'
    call nvim_set_current_win(s:yggdrasil_window)
endfunction

" Send an LSP request. Mock a source file if necessary, since
" some LSP clients accept calls only from within a source file.
function! s:request(filetype, bufnr, method, params, handler) abort
    let l:buftype = &buftype
    let l:temp_file_name = v:null
    let l:is_yggdrasil = &filetype ==# 'yggdrasil'

    try
        " If inside an yggdrasil buffer, mock a source file.
        if l:is_yggdrasil
            let l:temp_file_name = tempname()
            silent set buftype=
            silent execute 'set filetype=' . a:filetype
            silent execute 'file ' . l:temp_file_name
        endif

        " Send the request
        call ccls#lsp#request(a:bufnr, a:method, a:params, a:handler)
    finally
        " Restore yggdrasil buffer settings if necessary
        if l:is_yggdrasil
            silent set filetype=yggdrasil
            silent 0file
            silent execute 'set buftype=' . l:buftype
            call ccls#syntax#additional()
            if filereadable(l:temp_file_name)
                call delete(l:temp_file_name)
            endif
        endif
    endtry
endfunction

" Recursively cache the children.
function! s:add_children_to_cache(data) dict abort
    if !has_key(a:data, 'children') || len(a:data.children) < 1
        return
    endif

    let l:self.cached_children[a:data.id] = a:data.children
    for l:child in a:data.children
        call l:self.add_children_to_cache(l:child)
    endfor
endfunction

" Handle incominc children data.
function! s:handle_children_data(Callback, data) dict abort
    call l:self.add_children_to_cache(a:data)
    call a:Callback('success', a:data.children)
endfunction

" Produce the list of children for an object given as optional argument,
" or the root of the tree when called with no optional argument.
function! s:get_children(Callback, ...) dict abort
    if a:0 < 1
        call a:Callback('success', [l:self.root])
        return
    endif

    let l:data = a:1

    " Children already retrieved
    if has_key(l:data, 'children') && len(l:data.children) > 0
        call a:Callback('success', l:data.children)
        return
    endif

    " Cached children
    if has_key(l:self.cached_children, l:data.id)
        call a:Callback('success', l:self.cached_children[l:data.id])
        return
    endif

    " Request children from the server
    let l:params = {
    \   'id': l:data.id,
    \   'hierarchy': v:true,
    \   'levels': g:ccls_levels,
    \ }
    call extend(l:params, l:self.extra_params, 'force')
    if has_key(l:data, 'kind')
        let l:params['kind'] = l:data.kind
    endif

    let l:Handler = {data -> l:self.handle_children_data(a:Callback, data)}

    call ccls#util#message('Expanding node...')
    call s:request(l:self.filetype, l:self.bufnr, l:self.method, l:params, l:Handler)
endfunction

" Produce the parent of a given object.
function! s:get_parent(Callback, data) dict abort
    call a:Callback('failure')
endfunction

" Get the collapsibleState for a node. The root is returned expanded on
" the first request only (to avoid issues with cyclic graphs).
function! s:get_collapsible_state(data) dict abort
    let l:result = 'none'
    if a:data.numChildren > 0
        if a:data.id == l:self.root.id
            let l:result = l:self.root_state
            let l:self.root_state = 'collapsed'
        else
            let l:result = 'collapsed'
        endif
    endif
    return l:result
endfunction

" Get the label for a given node.
function! s:get_label(data) abort
    if has_key(a:data, 'fieldName') && len(a:data.fieldName)
        return a:data.fieldName
    else
        return a:data.name
    endif
endfunction

" Produce the tree item representation for a given object.
function! s:get_tree_item(Callback, data) dict abort
    let l:file = matchlist(a:data.location.uri, 'file://\(.*\)')[1]
    let l:line = str2nr(a:data.location.range.start.line) + 1
    let l:column = str2nr(a:data.location.range.start.character) + 1
    let l:tree_item = {
    \   'id': 0 + a:data.id,
    \   'command': function('s:jump_to', [l:file, l:line, l:column]),
    \   'preview': function('s:preview_to', [l:file, l:line, l:column]),
    \   'collapsibleState': l:self.get_collapsible_state(a:data),
    \   'label': s:get_label(a:data),
    \ }
    call a:Callback('success', l:tree_item)
endfunction

" Callback to create a tree view.
function! s:handle_tree(bufnr, filetype, method, extra_params, viewport, data) abort
    if type(a:data) != v:t_dict
        call ccls#util#warning('No hierarchy for the object under cursor')
        return
    endif

    " Create new buffer in a split
    if a:viewport ==? 'float' && exists('*nvim_open_win')
        let l:current_window = nvim_get_current_win()
        let s:buffer_options = {
        \   'style': 'minimal',
        \   'relative': 'win',
        \   'win': l:current_window,
        \   'bufpos': nvim_win_get_cursor(l:current_window),
        \   'width': g:ccls_float_width,
        \   'height': g:ccls_float_height,
        \   'row': 0,
        \   'col': 0,
        \ }
        let s:float_id = nvim_open_win(nvim_create_buf(v:false, v:true), 0, s:buffer_options)
        call win_gotoid(s:float_id)
    else
        let l:position = g:ccls_position =~# '\v^t|l' ? 'topleft' : 'botright'
        let l:orientation = g:ccls_orientation =~# '^v' ? 'vnew' : 'new'
        exec l:position . ' ' . g:ccls_size . l:orientation
    endif

    let l:provider = {
    \   'root': a:data,
    \   'root_state': 'expanded',
    \   'cached_children': {},
    \   'method': a:method,
    \   'filetype': a:filetype,
    \   'bufnr': a:bufnr,
    \   'extra_params': a:extra_params,
    \   'get_collapsible_state': function('s:get_collapsible_state'),
    \   'add_children_to_cache': function('s:add_children_to_cache'),
    \   'handle_children_data': function('s:handle_children_data'),
    \   'getChildren': function('s:get_children'),
    \   'getParent': function('s:get_parent'),
    \   'getTreeItem': function('s:get_tree_item'),
    \ }

    call ccls#yggdrasil#tree#new(l:provider)

    call ccls#syntax#additional()
endfunction

" Fill the quickfix list with the locations from LSP, and open it
function! s:handle_locations(data) abort
    let l:locations = []
    if !empty(a:data)
        for l:item in a:data
            let l:lnum = l:item.range.start.line + 1
            let l:col = l:item.range.start.character + 1
            let l:path = s:uri2path(l:item.uri)
            let l:text = readfile(l:path)[l:lnum - 1]

            call add(l:locations, {
            \   'filename': l:path,
            \   'lnum': l:lnum,
            \   'col': l:col,
            \   'text': l:text,
            \ })
        endfor
    endif
    call setqflist(l:locations)
    copen
endfunction

"
" Public API
"

function! ccls#messages#vars() abort
    call setqflist([])
    let l:params = {
    \   'textDocument': s:text_document_identifier(),
    \   'position': s:position(),
    \ }
    let l:Handler = function('s:handle_locations')
    call s:request(&filetype, bufnr('%'), '$ccls/vars', l:params, l:Handler)
    normal! m'
endfunction

function! ccls#messages#members(extra_params) abort
    call setqflist([])
    let l:params = {
    \   'textDocument': s:text_document_identifier(),
    \   'position': s:position(),
    \   'hierarchy': v:false,
    \ }
    call extend(l:params, a:extra_params)
    let l:Handler = function('s:handle_locations')
    call s:request(&filetype, bufnr('%'), '$ccls/member', l:params, l:Handler)
    normal! m'
endfunction

function! ccls#messages#member_hierarchy(extra_params, ...) abort
    let l:params = {
    \   'textDocument': s:text_document_identifier(),
    \   'position': s:position(),
    \   'hierarchy': v:true,
    \   'levels': g:ccls_levels,
    \ }
    call extend(l:params, a:extra_params)
    let l:bufnr = bufnr('%')
    let l:viewport = index(a:000, '-float') >= 0 ? 'float' : 'split'
    let l:Handler = function('s:handle_tree', [l:bufnr, &filetype, '$ccls/member', {}, l:viewport])
    call s:request(&filetype, l:bufnr, '$ccls/member', l:params, l:Handler)
    normal! m'
endfunction

function! ccls#messages#inheritance(derived) abort
    call setqflist([])
    let l:params = {
    \   'textDocument': s:text_document_identifier(),
    \   'position': s:position(),
    \   'hierarchy': v:false,
    \   'derived': a:derived,
    \ }
    let l:Handler = function('s:handle_locations')
    call s:request(&filetype, bufnr('%'), '$ccls/inheritance', l:params, l:Handler)
    normal! m'
endfunction

function! ccls#messages#inheritance_hierarchy(derived, ...) abort
    let l:params = {
    \   'textDocument': s:text_document_identifier(),
    \   'position': s:position(),
    \   'hierarchy': v:true,
    \   'levels': g:ccls_levels,
    \   'derived': a:derived,
    \ }
    let l:bufnr = bufnr('%')
    let l:viewport = index(a:000, '-float') >= 0 ? 'float' : 'split'
    let l:Handler = function('s:handle_tree', [l:bufnr, &filetype, '$ccls/inheritance', {'derived': a:derived}, l:viewport])
    call s:request(&filetype, l:bufnr, '$ccls/inheritance', l:params, l:Handler)
    normal! m'
endfunction

function! ccls#messages#calls(callee) abort
    call setqflist([])
    let l:params = {
    \   'textDocument': s:text_document_identifier(),
    \   'position': s:position(),
    \   'hierarchy': v:false,
    \   'callee': a:callee,
    \ }
    let l:Handler = function('s:handle_locations')
    call s:request(&filetype, bufnr('%'), '$ccls/call', l:params, l:Handler)
    normal! m'
endfunction

function! ccls#messages#call_hierarchy(callee, ...) abort
    let l:params = {
    \   'textDocument': s:text_document_identifier(),
    \   'position': s:position(),
    \   'hierarchy': v:true,
    \   'levels': g:ccls_levels,
    \   'callee': a:callee,
    \ }
    let l:bufnr = bufnr('%')
    let l:viewport = index(a:000, '-float') >= 0 ? 'float' : 'split'
    let l:Handler = function('s:handle_tree', [l:bufnr, &filetype, '$ccls/call', {'callee': a:callee}, l:viewport])
    call s:request(&filetype, l:bufnr, '$ccls/call', l:params, l:Handler)
    normal! m'
endfunction
