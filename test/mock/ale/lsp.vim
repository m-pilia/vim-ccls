source test/mock/ale/handlers/ccls.vim

if !exists('s:req_id')
    let s:req_id = 0
endif

if !exists('s:project_root')
    let s:project_root = ale#handlers#ccls#GetProjectRoot(0)
endif

if !exists('s:connections')
    let s:connections = {
    \   'ccls:' . s:project_root : {
    \       'root': s:project_root,
    \       'id': 'ccls:' . s:project_root,
    \       'data': '',
    \       'open_documents': {},
    \       'initialized': 1,
    \       'job_id': -1,
    \       'capabilities': {},
    \       'init_options': {},
    \       'callback_list': [],
    \       'init_queue': [],
    \       'init_request_id': 1,
    \       'is_tsserver': 0,
    \       'config': {},
    \   }
    \ }
endif

function! ale#lsp#GetConnections() abort
    return s:connections
endfunction

function! ale#lsp#RegisterCallback(conn_id, callback) abort
    call add(s:connections[a:conn_id].callback_list, a:callback)
endfunction

" NOTE: It is not possible to mock ALE synchronously, hence use a timer to call
" the callback, giving time to execute the rest of ccls#lsp#request() first.
" Add a reasonable sleep time between the call to ale#lsp#Send() and the
" assertions following it, to make sure that the callback has been executed
" before asserting.
function! ale#lsp#Send(conn_id, args) abort
    let s:req_id += 1
    let l:out = {
    \   'id': s:req_id,
    \   'result': ccls#mock(a:args[1], a:args[2]),
    \ }

    call timer_start(10, {tid -> s:connections[a:conn_id].callback_list[0](a:conn_id, l:out)})

    return s:req_id
endfunction
