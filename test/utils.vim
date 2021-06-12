" Get the names of currently sourced scripts
function! s:get_scripts() abort
    redir => l:out
    silent execute 'scriptnames'
    redir END
    return l:out
endfunction

" Get the name of a (possibly local) function from a script
function! s:get_function_name(script, name) abort
    if match(s:get_scripts(), a:script) < 0
        exec 'source ' . a:script
    endif
    for l:line in split(s:get_scripts(), '\n')
        if match(l:line, a:script) >= 0
            let l:sid = str2nr(split(l:line, ': ')[0])
            return '<SNR>' . l:sid . '_' . a:name
        endif
    endfor
endfunction

" Get a (possibly local) function from a script
function! GetFunction(script, name) abort
    return function(s:get_function_name(a:script, a:name))
endfunction

" Replace the implementation of a function with a mock
function! MockFunction(script, name, mock) abort
    let l:function_name = s:get_function_name(a:script, a:name)

    let l:code = "
    \\n    function! %s(...) abort closure
    \\n        return call(a:mock, a:000)
    \\n    endfunction
    \"

    execute printf(l:code, l:function_name)
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
