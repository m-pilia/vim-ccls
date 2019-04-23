" Print a warning message
function! s:warning(message) abort
    echohl WarningMsg
    echom a:message
    echohl None
endfunction

" Write arguments to the log file
function! s:log(...) abort
    if exists('g:lsp_ccls_log_file') && !empty(g:lsp_ccls_log_file)
        let l:data = [strftime('%c') . ' | ' . json_encode(a:000)]
        call writefile(l:data, g:lsp_ccls_log_file, 'a')
    endif
endfunction

" Handle a response from vim-lsc
function! s:vim_lsc_handler(handler, data) abort
    call s:log('Incoming', 'vim-lsc', a:data)
    call a:handler(a:data)
endfunction

" Handle a response from vim-lsp
function! s:vim_lsp_handler(handler, data) abort
    call s:log('Incoming', 'vim-lsp', a:data)
    if lsp#client#is_error(a:data.response)
        call s:warning('LSP error')
        return
    endif
    call a:handler(a:data.response.result)
endfunction

" Handle a response from LanguageClient-neovim
function! s:lcn_handler(handler, data) abort
    call s:log('Incoming', 'LanguageClient-neovim', a:data)
    if type(a:data) != v:t_dict ||
    \  has_key(a:data, 'error') ||
    \  !has_key(a:data, 'result')
        call s:warning('LSP error')
        return
    endif
    call a:handler(a:data.result)
endfunction

" Handle a response from coc.nvim
function! s:coc_handler(handler, error, data) abort
    call s:log('Incoming', 'coc.nvim', !!a:error ? a:error : a:data)
    if a:error
        call s:warning('LSP error')
        return
    endif
    call a:handler(a:data)
endfunction

" Make a request to the lsp server
" Try to automatically find an available LSP client
function! ccls#lsp#request(filetype, method, params, handler) abort
    let l:log_data = {
    \   'method': a:method,
    \   'params': a:params,
    \   'handler': string(a:handler)
    \ }
    call s:log('Outgoing', l:log_data)

    if exists('*lsc#server#call')
        " Use vim-lsc
        let l:Callback = function('s:vim_lsc_handler', [a:handler])
        call lsc#server#call(a:filetype, a:method, a:params, l:Callback)
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
        if len(l:available_servers) == 0 || count(l:available_servers, 'ccls') == 0
            call s:warning('ccls language server unvailable')
            return
        endif

        let l:request = {
        \   'method': a:method,
        \   'params': a:params,
        \   'on_notification': function('s:vim_lsp_handler', [a:handler]),
        \ }

        call lsp#send_request('ccls', l:request)
    else
        call s:warning('No LSP plugin found!')
    end
endfunction
