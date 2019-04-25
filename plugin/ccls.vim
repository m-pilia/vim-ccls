if exists('g:vim_ccls_plugin_loaded')
    finish
endif
let g:vim_ccls_plugin_loaded = 1

if !exists('g:ccls_close_on_jump')
    let g:ccls_close_on_jump = v:false
endif

if !exists('g:ccls_levels')
    let g:ccls_levels = 1
endif

if !exists('g:ccls_size')
    let g:ccls_size = 50
endif

if !exists('g:ccls_position')
    let g:ccls_position = 'topleft'
endif

if !exists('g:ccls_orientation')
    let g:ccls_orientation = 'vertical'
endif

command! CclsVars             call ccls#messages#vars()

command! CclsMembers          call ccls#messages#members()

command! CclsMemberHierarchy  call ccls#messages#member_hierarchy()

command! CclsBase             call ccls#messages#inheritance(v:false)
command! CclsDerived          call ccls#messages#inheritance(v:true)

command! CclsBaseHierarchy    call ccls#messages#inheritance_hierarchy(v:false)
command! CclsDerivedHierarchy call ccls#messages#inheritance_hierarchy(v:true)

command! CclsCallers          call ccls#messages#calls(v:false)
command! CclsCallees          call ccls#messages#calls(v:true)

command! CclsCallHierarchy    call ccls#messages#call_hierarchy(v:false)
command! CclsCalleeHierarchy  call ccls#messages#call_hierarchy(v:true)
