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
function! s:jump_to(file, line, column, node) abort
    let l:yggdrasil_bufno = bufnr('%')
    silent execute "normal! \<c-w>\<c-p>"
    if g:ccls_close_on_jump
        silent execute 'bd' . l:yggdrasil_bufno
    endif
    let l:buffer = bufnr(a:file)
    let l:command = l:buffer !=# -1 ? 'b ' . l:buffer : 'edit ' . a:file
    silent execute l:command . ' | call cursor(' . a:line . ',' . a:column . ')'
endfunction

" Callback to append the retrieved children to a node and update the tree
function! s:append_children(bufno, id, data) abort
    silent execute 'b' . a:bufno
    call s:make_children(a:id, 1, a:data.children)
    call b:yggdrasil_tree.render()
    redraw
    call ccls#util#message('Node expanded')
endfunction

" Lazily fetch the children of a node
function! s:lazy_open_callback(node_data, node) abort
    let l:bufno = b:yggdrasil_tree['buffer']
    let l:method = b:yggdrasil_tree['method']
    let l:Handler = {data -> s:append_children(l:bufno, a:node.id, data)}

    let l:params = {
    \   'id': a:node_data.id,
    \   'hierarchy': v:true,
    \   'levels': g:ccls_levels,
    \ }
    call extend(l:params, b:yggdrasil_tree.extra_params, 'force')
    if has_key(a:node_data, 'kind')
        let l:params['kind'] = a:node_data.kind
    endif

    call ccls#util#message('Expanding node...')
    call ccls#lsp#request(l:method, l:params, l:Handler)
endfunction

" For each child in the list, make a node and append it to the parent
function! s:make_children(parent_id, level, children_data) abort
    for l:child in a:children_data
        let l:file = matchlist(l:child.location.uri, 'file://\(.*\)')[1]
        let l:line = str2nr(l:child.location.range.start.line) + 1
        let l:column = str2nr(l:child.location.range.start.character) + 1
        let l:Callback = function('s:jump_to', [l:file, l:line, l:column])
        let l:name = has_key(l:child, 'fieldName') ? l:child.fieldName : l:child.name

        " Do not fetch nodes beyond the requested depth
        " Create a callback to fetch the subtree lazily
        let l:Lazy_open = v:null
        if l:child.numChildren > 0 && a:level >= g:ccls_levels
            let l:Lazy_open = function('s:lazy_open_callback', [l:child])
        endif

        let l:node = b:yggdrasil_tree.insert(l:name, l:Callback, l:Lazy_open, a:parent_id)

        " Recursive call to create children
        if l:child.numChildren > 0 && a:level < g:ccls_levels
            call s:make_children(l:node.id, a:level + 1, l:child.children)
        endif
    endfor
endfunction

" Callback to create an Yggdrasil window
function! s:make_tree(method, extra_params, data) abort
    if type(a:data) != v:t_dict
        call ccls#util#warning('No hierarchy for the object under cursor')
        return
    endif

    let l:filetype = &filetype
    let l:calling_buffer = bufnr('%')

    call yggdrasil#tree#new(g:ccls_size,
    \                       g:ccls_position,
    \                       g:ccls_orientation)

    " Store additional information in the tree structure
    " to avoid having too many arguments in the callbacks
    let b:yggdrasil_tree['buffer'] = bufnr('%')
    let b:yggdrasil_tree['calling_buffer'] = l:calling_buffer
    let b:yggdrasil_tree['filetype'] = l:filetype
    let b:yggdrasil_tree['extra_params'] = a:extra_params
    let b:yggdrasil_tree['method'] = a:method

    call s:make_children(v:null, 0, [a:data])
    let b:yggdrasil_tree.root.label = a:data.name
    call b:yggdrasil_tree.render()
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
    call ccls#lsp#request('$ccls/vars', l:params, l:Handler)
endfunction

function! ccls#messages#members() abort
    call setqflist([])
    let l:params = {
    \   'textDocument': s:text_document_identifier(),
    \   'position': s:position(),
    \   'hierarchy': v:false,
    \ }
    let l:Handler = function('s:handle_locations')
    call ccls#lsp#request('$ccls/member', l:params, l:Handler)
endfunction

function! ccls#messages#member_hierarchy() abort
    let l:params = {
    \   'textDocument': s:text_document_identifier(),
    \   'position': s:position(),
    \   'hierarchy': v:true,
    \   'levels': g:ccls_levels,
    \ }
    let l:Handler = function('s:make_tree', ['$ccls/member', {}])
    call ccls#lsp#request('$ccls/member', l:params, l:Handler)
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
    call ccls#lsp#request('$ccls/inheritance', l:params, l:Handler)
endfunction

function! ccls#messages#inheritance_hierarchy(derived) abort
    let l:params = {
    \   'textDocument': s:text_document_identifier(),
    \   'position': s:position(),
    \   'hierarchy': v:true,
    \   'levels': g:ccls_levels,
    \   'derived': a:derived,
    \ }
    let l:Handler = function('s:make_tree', ['$ccls/inheritance', {'derived': a:derived}])
    call ccls#lsp#request('$ccls/inheritance', l:params, l:Handler)
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
    call ccls#lsp#request('$ccls/call', l:params, l:Handler)
endfunction

function! ccls#messages#call_hierarchy(callee) abort
    let l:params = {
    \   'textDocument': s:text_document_identifier(),
    \   'position': s:position(),
    \   'hierarchy': v:true,
    \   'levels': g:ccls_levels,
    \   'callee': a:callee,
    \ }
    let l:Handler = function('s:make_tree', ['$ccls/call', {'callee': a:callee}])
    call ccls#lsp#request('$ccls/call', l:params, l:Handler)
endfunction
