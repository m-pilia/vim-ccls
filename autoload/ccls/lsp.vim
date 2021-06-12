" Handle a response from ALE
function! s:ale_handler(handler, data) abort
    call ccls#util#log('Incoming', 'ALE', a:data)
    if type(a:data) != v:t_dict ||
    \  has_key(a:data, 'error') ||
    \  !has_key(a:data, 'result')
        call ccls#util#warning('LSP error')
        return
    endif
    call a:handler(a:data.result)
endfunction

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

" Handle a response from nvim-lspconfig
function! s:nvim_lspconfig_handler(handler, data) abort
    call ccls#util#log('Incoming', 'nvim-lspconfig', a:data)
    call a:handler(a:data)
endfunction

" Make a request to the lsp server
" Try to automatically find an available LSP client
function! ccls#lsp#request(bufnr, method, params, handler) abort
    let l:log_data = {
    \   'method': a:method,
    \   'params': a:params,
    \   'handler': get(a:handler, 'name')
    \ }
    call ccls#util#log('Outgoing', l:log_data)

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
    elseif exists('*ale#lsp_linter#SendRequest')
        " Use ALE
        let l:message = [0, a:method, a:params]
        let l:Callback = function('s:ale_handler', [a:handler])

        try
            call ale#lsp_linter#SendRequest(a:bufnr, 'ccls', l:message, l:Callback)
        catch
            call ccls#util#warning('LSP error')
        endtry
    elseif get(g:, 'lspconfig', v:false)
        " Use nvim-lspconfig
        let l:Callback = function('s:nvim_lspconfig_handler', [a:handler])
        let l:call_id = ccls#lsp#nvim_lspconfig#register(l:Callback)
        let l:args = [a:bufnr, a:method, a:params, l:call_id]
        call luaeval('require("vim_ccls").request(unpack(_A))', l:args)
    else
        call ccls#util#warning('No LSP plugin found!')
    end
endfunction
