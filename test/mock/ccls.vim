let s:request_id = 0
let s:node_type = ''

let s:valid_methods = [
\   '$ccls/call',
\   '$ccls/inheritance',
\   '$ccls/member',
\   '$ccls/vars',
\ ]

"   0
"  / \
" 1   2
"    / \
"   3   4
let s:tree_structure = {
\   0: [1, 2],
\   1: [],
\   2: [3, 4],
\   3: [],
\   4: [],
\ }

function! s:make_node(id, type)
    let l:node = {
    \     'id': a:id,
    \     'name': 'node_' . a:id,
    \     'location': {
    \         'uri': 'file:///node/' . a:id,
    \         'range': {
    \             'start': {
    \                 'character': 100 * a:id + 00,
    \                 'line':      100 * a:id + 01,
    \             },
    \             'end': {
    \                 'character': 100 * a:id + 10,
    \                 'line':      100 * a:id + 11,
    \             },
    \         }
    \     },
    \     'numChildren': 0,
    \     'children': [],
    \ }

    if a:type ==? '$ccls/call'
        let l:node['callType'] = 0
    elseif a:type ==? '$ccls/inheritance'
        let l:node['kind'] = 2
    elseif a:type ==? '$ccls/member'
        let l:node['fieldName'] = 'field_' . a:id
    else
        echoerr 'Unrecognised node type "' . a:type . '"'
        return
    endif

    return l:node
endfunction

function! s:build_subtree(node, method, level, max_level) abort
    let a:node.numChildren += len(s:tree_structure[a:node.id])

    if a:level > a:max_level
        return
    endif

    for l:id in s:tree_structure[a:node.id]
        let l:new_child = s:make_node(l:id, a:method)
        call add(a:node.children, l:new_child)
        call s:build_subtree(l:new_child, a:method, a:level + 1, a:max_level)
    endfor
endfunction

function! s:build_list_item(params, offset) abort
    let l:item = {
    \   'uri': 'test/example.cpp',
    \   'range': {
    \       'end': deepcopy(a:params.position),
    \       'start': deepcopy(a:params.position),
    \   },
    \ }
    let l:item.range.start.line += a:offset
    let l:item.range.end.line += a:offset
    return l:item
endfunction

function! ccls#mock(method, params) abort
    if index(s:valid_methods, a:method) < 0
        echoerr 'Unexpected method "' . a:method . '"'
        return
    endif

    let s:request_id += 1

    if has_key(a:params, 'hierarchy') && a:params.hierarchy

        " Both id and kind are required to expand an inheritance node
        if a:method ==# '$ccls/inheritance' &&
        \  has_key(a:params, 'id') &&
        \  !has_key(a:params, 'kind')
            return v:null
        endif

        let l:id = has_key(a:params, 'id') ? a:params.id : 0
        let l:node = s:make_node(l:id, a:method)
        call s:build_subtree(l:node, a:method, 1, a:params.levels)
        return l:node
    else
        return [
        \   s:build_list_item(a:params, 0),
        \   s:build_list_item(a:params, 1),
        \   s:build_list_item(a:params, 2),
        \ ]
    endif
endfunction
