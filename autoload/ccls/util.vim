" Print a warning message
function! ccls#util#warning(message) abort
    redraw
    echohl WarningMsg
    echom 'vim-ccls: ' . a:message
    echohl None
endfunction

" Print a message
function! ccls#util#message(message) abort
    if !g:ccls_quiet
        redraw
        echom 'vim-ccls: ' . a:message
    endif
endfunction

" Write arguments to the log file
function! ccls#util#log(...) abort
    if exists('g:ccls_log_file') && !empty(g:ccls_log_file)
        let l:data = [strftime('%c') . ' | ' . json_encode(a:000)]
        call writefile(l:data, g:ccls_log_file, 'a')
    endif
endfunction

