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

" Get a list of echoed messages
function! GetMessages() abort
    redir => l:out
    silent execute 'messages'
    redir END
    return split(l:out, '\n')
endfunction

" Check if a syntax group exists
function! s:assert_syntax(group) abort
    try
        execute 'syntax list ' a:group
        Assert 1, 'Syntax group "' . a:group . '" is defined'
    catch
        Assert 0, 'Syntax group "' . a:group . '" is not defined'
    endtry
endfunction

command! -nargs=1 AssertSyntax :call s:assert_syntax(<f-args>)

" Get a list of echoed messages
function! s:get_messages() abort
    redir => l:out
    silent execute 'messages'
    redir END
    return split(l:out, '\n')
endfunction

" Assert that a certain message was emitted
function! s:assert_message(message, expected) abort
    let l:index = index(s:get_messages(), a:message)
    Assert
    \   (a:expected ? l:index > -1 : l:index < 0),
    \   'Message "' . a:message . (a:expected ? '" not emitted' : '" emitted')
endfunction

command! -nargs=1 AssertMessage :call s:assert_message(<args>, v:true)
command! -nargs=1 AssertNoMessage :call s:assert_message(<args>, v:false)
