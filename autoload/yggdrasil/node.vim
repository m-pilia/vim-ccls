scriptencoding utf-8

function! yggdrasil#node#set_collapsed(value, recursive) dict abort
    if a:value < 1 && l:self.lazy_open != v:null
        call l:self.lazy_open(l:self)
        let l:self.lazy_open = v:null
        let l:self.collapsed = v:false
    else
        let l:self.collapsed = a:value < 0 ? !l:self.collapsed : !!a:value
    endif
    if a:recursive
        for l:child in l:self.children
            call l:child.set_collapsed(a:value, a:recursive)
        endfor
    endif
endfunction

function! yggdrasil#node#find(id) dict abort
    if l:self.id == a:id
        return l:self
    endif
    if len(l:self.children) < 1
        return v:null
    endif
    for l:child in l:self.children
        let l:result = l:child.find(a:id)
        if type(l:result) == type({})
            return l:result
        endif
    endfor
endfunction

function! yggdrasil#node#exec() dict abort
    if l:self.callback != v:null
        call l:self.callback(l:self)
    endif
endfunction

function! yggdrasil#node#level() dict abort
    if l:self.parent == {}
        return 0
    endif
    return 1 + l:self.parent.level()
endf

function! yggdrasil#node#render(level) dict abort
    let l:indent = repeat(' ', 2 * a:level)
    let l:mark = '  '

    if len(l:self.children) > 0 || l:self.lazy_open != v:null
        let l:mark = l:self.collapsed ? '▸ ' : '▾ '
    endif

    let l:repr = l:indent . l:mark . l:self.label . ' [' . l:self.id . ']'

    let l:lines = [l:repr]
    if !l:self.collapsed
        for l:child in l:self.children
            cal add(l:lines, l:child.render(a:level + 1))
        endfor
    endif

    return join(l:lines, "\n")
endfunction

function! yggdrasil#node#append(id, label, callback, lazy_open) dict abort
    call add(
    \   l:self.children,
    \   yggdrasil#node#new(a:id, a:label, l:self, a:callback, a:lazy_open))
endfunction

function! yggdrasil#node#new(id, label, parent, callback, lazy_open) abort
    return {
    \ 'id': a:id,
    \ 'label': a:label,
    \ 'parent': a:parent,
    \ 'collapsed': v:true,
    \ 'lazy_open': a:lazy_open,
    \ 'callback': a:callback,
    \ 'children': [],
    \ 'level': function('yggdrasil#node#level'),
    \ 'find': function('yggdrasil#node#find'),
    \ 'exec': function('yggdrasil#node#exec'),
    \ 'append': function('yggdrasil#node#append'),
    \ 'set_collapsed': function('yggdrasil#node#set_collapsed'),
    \ 'render': function('yggdrasil#node#render'),
    \ }
endfunction
