if exists('g:lsp_ccls_loaded')
    finish
endif
let g:lsp_ccls_loaded = 1

if !exists('g:lsp_ccls_close_on_jump')
    let g:lsp_ccls_close_on_jump = v:false
endif

if !exists('g:lsp_ccls_levels')
    let g:lsp_ccls_levels = 1
endif

if !exists('g:lsp_ccls_size')
    let g:lsp_ccls_size = 50
endif

if !exists('g:lsp_ccls_position')
    let g:lsp_ccls_position = 'topleft'
endif

if !exists('g:lsp_ccls_orientation')
    let g:lsp_ccls_orientation = 'vertical'
endif

command! LspCclsVars             call ccls#messages#vars()

command! LspCclsMembers          call ccls#messages#members()

command! LspCclsMemberHierarchy  call ccls#messages#member_hierarchy()

command! LspCclsBase             call ccls#messages#inheritance(v:false)
command! LspCclsDerived          call ccls#messages#inheritance(v:true)

command! LspCclsBaseHierarchy    call ccls#messages#inheritance_hierarchy(v:false)
command! LspCclsDerivedHierarchy call ccls#messages#inheritance_hierarchy(v:true)

command! LspCclsCallers          call ccls#messages#calls(v:false)
command! LspCclsCallees          call ccls#messages#calls(v:true)

command! LspCclsCallHierarchy    call ccls#messages#call_hierarchy(v:false)
command! LspCclsCalleeHierarchy  call ccls#messages#call_hierarchy(v:true)
