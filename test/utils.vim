" Get the names of currently sourced scripts
function! s:get_scripts() abort
    redir => l:out
    silent execute 'scriptnames'
    redir END
    return l:out
endfunction

" Get a (possibly local) function from a script
function! GetFunction(script, name) abort
    if match(s:get_scripts(), a:script) < 0
        exec 'source ' . a:script
    endif
    for l:line in split(s:get_scripts(), '\n')
        if match(l:line, a:script) >= 0
            let l:sid = str2nr(split(l:line, ': ')[0])
            return function('<SNR>' . l:sid . '_' . a:name)
        endif
    endfor
endfunction
