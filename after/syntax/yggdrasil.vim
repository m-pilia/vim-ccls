scriptencoding utf-8

syntax include @cpp syntax/cpp.vim

syntax match CclsAnonymousNamespace "\v\(@<=anonymous namespace\)@=" contained
syntax match CclsLabel "\v^(\s|[▸▾])*.*( \[\d+\])@=" contains=YggdrasilMarkCollapsed,YggdrasilMarkExpanded,CclsAnonymousNamespace,@cpp

highlight def link CclsAnonymousNamespace CppStructure
highlight def link CclsLabel Identifier
