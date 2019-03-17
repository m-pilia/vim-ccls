scriptencoding utf-8

syntax match YggdrasilId              "\v\[\d+\]$" conceal
syntax match YggdrasilMarkCollapsed   "▸" contained
syntax match YggdrasilMarkExpanded    "▾" contained
syntax match YggdrasilLabel           "\v^(\s|[▸▾])*.*( \[\d+\])@=" contains=YggdrasilMarkCollapsed,YggdrasilMarkExpanded

highlight def link YggdrasilMarkExpanded    Type
highlight def link YggdrasilMarkCollapsed   Macro
highlight def link YggdrasilLabel           Identifier
