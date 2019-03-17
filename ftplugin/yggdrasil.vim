setlocal bufhidden=wipe
setlocal buftype=nofile
setlocal concealcursor=nvic
setlocal conceallevel=3
setlocal foldcolumn=0
setlocal foldmethod=manual
setlocal nobuflisted
setlocal nofoldenable
setlocal nohlsearch
setlocal nolist
setlocal nomodifiable
setlocal nonumber
setlocal nospell
setlocal noswapfile
setlocal nowrap

nnoremap <silent> <buffer> <Plug>(yggdrasil-toggle-node)
    \ :call b:yggdrasil_tree.set_collapsed_under_cursor(-1, v:false)<cr>

nnoremap <silent> <buffer> <Plug>(yggdrasil-open-node)
    \ :call b:yggdrasil_tree.set_collapsed_under_cursor(v:false, v:false)<cr>

nnoremap <silent> <buffer> <Plug>(yggdrasil-close-node)
    \ :call b:yggdrasil_tree.set_collapsed_under_cursor(v:true, v:false)<cr>

nnoremap <silent> <buffer> <Plug>(yggdrasil-open-subtree)
    \ :call b:yggdrasil_tree.set_collapsed_under_cursor(v:false, v:true)<cr>

nnoremap <silent> <buffer> <Plug>(yggdrasil-close-subtree)
    \ :call b:yggdrasil_tree.set_collapsed_under_cursor(v:true, v:true)<cr>

nnoremap <silent> <buffer> <Plug>(yggdrasil-execute-node)
    \ :call b:yggdrasil_tree.get_node_id_under_cursor().exec()<cr>

if !exists('g:yggdrasil_no_default_maps')
    nmap <silent> <buffer> o    <Plug>(yggdrasil-toggle-node)
    nmap <silent> <buffer> O    <Plug>(yggdrasil-open-subtree)
    nmap <silent> <buffer> C    <Plug>(yggdrasil-close-subtree)
    nmap <silent> <buffer> <cr> <Plug>(yggdrasil-execute-node)

    nnoremap <silent> <buffer> q :q<cr>
endif
