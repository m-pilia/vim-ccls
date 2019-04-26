" Handle a response from vim-lsc
function! s:vim_lsc_handler(handler, data) abort
    call ccls#util#log('Incoming', 'vim-lsc', a:data)
    call a:handler(a:data)
endfunction

" Handle a response from vim-lsp
function! s:vim_lsp_handler(handler, data) abort
    call ccls#util#log('Incoming', 'vim-lsp', a:data)
    if lsp#client#is_error(a:data.response)
        call ccls#util#warning('LSP error')
        return
    endif
    call a:handler(a:data.response.result)
endfunction

" Handle a response from LanguageClient-neovim
function! s:lcn_handler(handler, data) abort
    call ccls#util#log('Incoming', 'LanguageClient-neovim', a:data)
    if type(a:data) != v:t_dict ||
    \  has_key(a:data, 'error') ||
    \  !has_key(a:data, 'result')
        call ccls#util#warning('LSP error')
        return
    endif
    call a:handler(a:data.result)
endfunction

" Handle a response from coc.nvim
function! s:coc_handler(handler, error, data) abort
    call ccls#util#log('Incoming', 'coc.nvim', !!a:error ? a:error : a:data)
    if a:error
        call ccls#util#warning('LSP error')
        return
    endif
    call a:handler(a:data)
endfunction

" Make a request to the lsp server
" Try to automatically find an available LSP client
function! ccls#lsp#request(method, params, handler) abort
    let l:log_data = {
    \   'method': a:method,
    \   'params': a:params,
    \   'handler': string(a:handler)
    \ }
    call ccls#util#log('Outgoing', l:log_data)

    let l:buftype = &buftype
    let l:temp_file_name = v:null
    let l:is_yggdrasil = &filetype ==# 'yggdrasil'

    try
        " If inside an yggdrasil buffer, mock a source file.
        " This because some LSP clients accept calls only
        " from what seems to be a legit source file.
        if l:is_yggdrasil
            let l:temp_file_name = tempname()
            silent set buftype=
            silent execute 'set filetype=' . b:yggdrasil_tree['filetype']
            silent execute 'file ' . l:temp_file_name
        endif

        if exists('*lsc#server#userCall')
            " Use vim-lsc
            let l:Callback = function('s:vim_lsc_handler', [a:handler])
            call lsc#server#userCall(a:method, a:params, l:Callback)
        elseif exists('*LanguageClient#Call')
            " Use LanguageClient-neovim
            let l:Callback = function('s:lcn_handler', [a:handler])
            call LanguageClient#Call(a:method, a:params, l:Callback)
        elseif exists('*CocRequestAsync')
            " Use coc.nvim
            let l:Callback = function('s:coc_handler', [a:handler])
            call CocRequestAsync('ccls', a:method, a:params, l:Callback)
        elseif exists('*lsp#send_request')
            " Use vim-lsp
            let l:available_servers = lsp#get_server_names()
            if len(l:available_servers) != 0 &&
            \  count(l:available_servers, 'ccls') != 0
                let l:request = {
                \   'method': a:method,
                \   'params': a:params,
                \   'on_notification': function('s:vim_lsp_handler', [a:handler]),
                \ }

                call lsp#send_request('ccls', l:request)
            else
                call ccls#util#warning('ccls language server unvailable')
            endif
        else
            call ccls#util#warning('No LSP plugin found!')
        end
    finally
        " Restore yggdrasil buffer settings if necessary
        if l:is_yggdrasil
            silent set filetype=yggdrasil
            silent 0file
            silent execute 'set buftype=' . l:buftype
            if filereadable(l:temp_file_name)
                call delete(l:temp_file_name)
            endif
        endif
    endtry
endfunction
