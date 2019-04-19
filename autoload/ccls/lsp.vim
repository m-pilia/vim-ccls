" Print a warning message
function! s:warning(message) abort
    echohl WarningMsg
    echom a:message
    echohl None
endfunction

" Handle a response from vim-lsp
function! s:vim_lsp_handler(handler, data) abort
    if lsp#client#is_error(a:data.response)
        call s:warning('LSP error')
        return
    endif
    call a:handler(a:data.response.result)
endfunction

" Handle a response from LanguageClient-neovim
function! s:lcn_handler(handler, data) abort
    if type(a:data) != v:t_dict ||
    \  has_key(a:data, 'error') ||
    \  !has_key(a:data, 'result') ||
    \  type(a:data.result) != v:t_dict
        call s:warning('LSP error')
        return
    endif
    call a:handler(a:data.result)
endfunction

" Make a request to the lsp server
" Try to automatically find an available LSP client
function! ccls#lsp#request(filetype, method, params, handler) abort
    if exists('*lsc#server#call')
        " Use vim-lsc
        call lsc#server#call(a:filetype, '$ccls/' . a:method, a:params, a:handler)
    elseif exists('*LanguageClient#Call')
        " Use LanguageClient-neovim
        let l:Callback = function('s:lcn_handler', [a:handler])
        call LanguageClient#Call('$ccls/' . a:method, a:params, l:Callback)
    elseif exists('*lsp#send_request')
        " Use vim-lsp
        let l:available_servers = lsp#get_server_names()
        if len(l:available_servers) == 0 || count(l:available_servers, 'ccls') == 0
            call s:warning('ccls language server unvailable')
            return
        endif

        let l:request = {
        \   'method': '$ccls/' . a:method,
        \   'params': a:params,
        \   'on_notification': function('s:vim_lsp_handler', [a:handler]),
        \ }

        call lsp#send_request('ccls', l:request)
    end
endfunction
