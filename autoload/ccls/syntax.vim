scriptencoding utf-8

" Additional syntax highlighting for C and C++
function! ccls#syntax#additional() abort
    syntax include @cpp syntax/cpp.vim

    syntax match CclsAnonymousNamespace "\v\(@<=anonymous namespace\)@=" contained
    syntax match CclsLabel "\v^(\s|[▸▾•])*.*"
    \       contains=YggdrasilMarkLeaf,YggdrasilMarkCollapsed,YggdrasilMarkExpanded,CclsAnonymousNamespace,@cpp

    highlight def link CclsAnonymousNamespace CppStructure
    highlight def link CclsLabel Identifier
endfunction
