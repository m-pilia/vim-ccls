scriptencoding utf-8

syntax include @cpp syntax/cpp.vim

syntax match CclsLabel "\v^(\s|[▸▾])*.*( \[\d+\])@=" contains=YggdrasilMarkCollapsed,YggdrasilMarkExpanded,@cpp

highlight def link CclsLabel Identifier
