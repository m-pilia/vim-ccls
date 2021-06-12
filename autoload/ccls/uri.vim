function! s:is_windows() abort
    return has('win32') || has('win64') || has('win32unix')
endfunction

function! s:is_cygwin() abort
    return has('win32unix')
endfunction

function! s:encode_character(c) abort
    return printf('%%%02X', char2nr(a:c))
endfunction

function! s:encode_path(path) abort
    let l:encoded_path = ''
    for l:index in range(0, len(a:path) - 1)
        if a:path[l:index] =~# '^[a-zA-Z0-9_.~/-]$'
            let l:encoded_path .= a:path[l:index]
        else
            let l:encoded_path .= s:encode_character(a:path[l:index])
        endif
    endfor
    return l:encoded_path
endfunction

" Convert a path to an uri
function! ccls#uri#path2uri(path) abort
    let l:path = a:path

    if s:is_cygwin()
        let l:path = substitute(l:path, '\c^/\([A-Z]\)/', '\U\1:/', '')
    endif

    let l:prefix = matchstr(l:path, '\v(^\w+::|^\w+://)')
    if len(l:prefix) < 1
        let l:prefix = 'file:///'
    else
        " Non-local path
        return l:path
    endif

    let l:path = substitute(l:path, '^/', '', '')
    let l:path = substitute(l:path, '\', '/', 'g')

    let l:volume_end = s:is_windows() ? matchstrpos(l:path, '\c[A-Z]:')[2] : 0
    if l:volume_end < 0
        let l:volume_end = 0
    endif

    let l:volume = strpart(l:path, 0, l:volume_end)
    let l:encoded_path = s:encode_path(l:path[l:volume_end :])

    return l:prefix . l:volume . l:encoded_path
endfunction

" Convert an uri to a path
function! ccls#uri#uri2path(uri) abort
    let l:path = substitute(a:uri, '^file://', '', '')
    let l:path = substitute(l:path, '[?#].*', '', '')
    let l:path = substitute(l:path,
    \                       '%\(\x\x\)',
    \                       '\=printf("%c", str2nr(submatch(1), 16))',
    \                       'g')
    if s:is_windows()
        if s:is_cygwin()
            let l:path = substitute(l:path, '\c^/\([A-Z]\):/', '/\l\1/', '')
        else
            let l:path = substitute(l:path, '^/', '', '')
            let l:path = substitute(l:path, '/', '\\', 'g')
        endif
    endif
    return l:path
endfunction


