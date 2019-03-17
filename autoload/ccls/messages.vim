function! s:jump_to(file, line, column, node) abort
    let l:yggdrasil_bufno = bufnr('%')
    silent execute "normal! \<c-w>\<c-p>"
    if g:lsp_ccls_close_on_jump
        silent execute 'bd' . l:yggdrasil_bufno
    endif
    let l:buffer = bufnr(a:file)
    let l:command = l:buffer !=# -1 ? 'b ' . l:buffer : 'edit ' . a:file
    silent execute l:command . ' | call cursor(' . a:line . ',' . a:column . ')'
endfunction

function! s:append_children(id, data) abort
    if lsp#client#is_error(a:data.response)
        echoerr 'LSP error'
        return
    endif

    let l:children_data = a:data.response.result.children
    call s:make_children(a:id, 1, l:children_data)
    call b:yggdrasil_tree.render()
endfunction

function! s:lazy_open_callback(parent_id, node) abort
    let l:method = b:yggdrasil_tree.method
    let l:extra_params = b:yggdrasil_tree.extra_params

    " FIXME horrible hack
    " When sending a request, vim-lsp requires the file in the current buffer to
    " be open in the LS. Jump back to previous window before sending the
    " request, so it will check for the file in its buffer, instead of the
    " Yggdrasil buffer.
    silent execute "normal! \<c-w>\<c-p>"

    let l:request = {
    \   'method': l:method,
    \   'params': {
    \       'id': a:parent_id,
    \       'hierarchy': v:true,
    \       'levels': g:lsp_ccls_levels,
    \   },
    \   'on_notification': {data -> s:append_children(a:node.id, data)},
    \ }
    call extend(l:request.params, l:extra_params, 'force')

    call lsp#send_request('ccls', l:request)

    " Jump back to the Yggdrasil window after sending the request
    silent execute "normal! \<c-w>\<c-p>"
endfunction

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
        if l:child.numChildren > 0 && a:level >= g:lsp_ccls_levels
            let l:params = {
            \   'id': l:child.id,
            \   'hierarchy': v:true,
            \   'levels': g:lsp_ccls_levels,
            \ }
            call extend(l:params, b:yggdrasil_tree.extra_params, 'force')
            let l:Lazy_open = function('s:lazy_open_callback', [l:child.id])
        endif

        let l:node = b:yggdrasil_tree.insert(a:parent_id, l:name, l:Callback, l:Lazy_open)

        " Recursive call to create children
        if l:child.numChildren > 0 && a:level < g:lsp_ccls_levels
            call s:make_children(l:node.id, a:level + 1, l:child.children)
        endif
    endfor
endfunction

function! s:make_tree(extra_params, data) abort
    if lsp#client#is_error(a:data.response)
        echoerr 'LSP error'
        return
    endif

    call yggdrasil#tree#new(a:data.response.result.name,
    \                       g:lsp_ccls_size,
    \                       g:lsp_ccls_position,
    \                       g:lsp_ccls_orientation)

    " Store additional information in the tree structure
    " to avoid having too many arguments in the callbacks
    let b:yggdrasil_tree['extra_params'] = a:extra_params
    let b:yggdrasil_tree['method'] = a:data.request.method

    let l:children_data = a:data.response.result.children
    call s:make_children('0', 1, l:children_data)
    call b:yggdrasil_tree.render()
endfunction

function! s:send_request(method, params, handler) abort
    let l:available_servers = lsp#get_server_names()
    if len(l:available_servers) == 0 || count(l:available_servers, 'ccls') == 0
        echoerr 'ccls language server unvailable'
        return
    endif

    let l:request = {
    \   'method': '$ccls/' . a:method,
    \   'params': a:params,
    \   'on_notification': a:handler,
    \ }

    call lsp#send_request('ccls', l:request)
endfunction

function! s:handle_locations(data) abort
    if lsp#client#is_error(a:data.response)
        echoerr 'LSP error: ' . a:data
        return
    endif

    call setqflist(lsp#ui#vim#utils#locations_to_loc_list(a:data))
    botright copen
endfunction

"
" Public API
"

function! ccls#messages#vars() abort
    call setqflist([])
    let l:params = {
    \   'textDocument': lsp#get_text_document_identifier(),
    \   'position': lsp#get_position(),
    \ }
    call s:send_request('vars', l:params, function('s:handle_locations'))
endfunction

function! ccls#messages#members() abort
    call setqflist([])
    let l:params = {
    \   'textDocument': lsp#get_text_document_identifier(),
    \   'position': lsp#get_position(),
    \   'hierarchy': v:false,
    \ }
    call s:send_request('member', l:params, function('s:handle_locations'))
endfunction

function! ccls#messages#member_hierarchy() abort
    let l:params = {
    \   'textDocument': lsp#get_text_document_identifier(),
    \   'position': lsp#get_position(),
    \   'hierarchy': v:true,
    \   'levels': g:lsp_ccls_levels,
    \ }
    let l:Handler = function('s:make_tree', [{}])
    call s:send_request('member', l:params, l:Handler)
endfunction

function! ccls#messages#inheritance(derived) abort
    call setqflist([])
    let l:params = {
    \   'textDocument': lsp#get_text_document_identifier(),
    \   'position': lsp#get_position(),
    \   'hierarchy': v:false,
    \   'derived': a:derived,
    \ }
    call s:send_request('inheritance', l:params, function('s:handle_locations'))
endfunction

function! ccls#messages#inheritance_hierarchy(derived) abort
    let l:params = {
    \   'textDocument': lsp#get_text_document_identifier(),
    \   'position': lsp#get_position(),
    \   'hierarchy': v:true,
    \   'levels': g:lsp_ccls_levels,
    \   'derived': a:derived,
    \ }
    let l:Handler = function('s:make_tree', [{'derived': a:derived}])
    call s:send_request('inheritance', l:params, l:Handler)
endfunction

function! ccls#messages#calls(callee) abort
    call setqflist([])
    let l:params = {
    \   'textDocument': lsp#get_text_document_identifier(),
    \   'position': lsp#get_position(),
    \   'hierarchy': v:false,
    \   'callee': a:callee,
    \ }
    call s:send_request('call', l:params, function('s:handle_locations'))
endfunction

function! ccls#messages#call_hierarchy(callee) abort
    let l:params = {
    \   'textDocument': lsp#get_text_document_identifier(),
    \   'position': lsp#get_position(),
    \   'hierarchy': v:true,
    \   'levels': g:lsp_ccls_levels,
    \   'callee': a:callee,
    \ }
    let l:Handler = function('s:make_tree', [{'callee': a:callee}])
    call s:send_request('call', l:params, l:Handler)
endfunction
