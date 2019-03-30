" Call a script-local function
function! Call(script, name, ...) abort
    exec 'source ' . b:script
    redir => l:out
    silent execute 'scriptnames'
    redir END
    let l:sid = ''
    for l:line in split(l:out, '\n')
        if match(l:line, a:script) >= 0
            let l:sid = str2nr(split(l:line, ': ')[0])
            break
        endif
    endfor
    return call('<SNR>' . l:sid . '_' . a:name, a:000)
endfunction
