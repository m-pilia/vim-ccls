if exists('g:vim_ccls_plugin_loaded')
    finish
endif
let g:vim_ccls_plugin_loaded = 1

if !exists('g:ccls_close_on_jump')
    let g:ccls_close_on_jump = v:false
endif

if !exists('g:ccls_float_width')
    let g:ccls_float_width = 50
endif

if !exists('g:ccls_float_height')
    let g:ccls_float_height = 20
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

if !exists('g:ccls_quiet')
    let g:ccls_quiet = 0
endif

command! CclsVars                      call ccls#messages#vars()

command! CclsMembers                   call ccls#messages#members({})
command! CclsMemberFunctions           call ccls#messages#members({'kind': 3})
command! CclsMemberTypes               call ccls#messages#members({'kind': 2})

command! -nargs=* CclsMemberHierarchy         call ccls#messages#member_hierarchy({}, <f-args>)
command! -nargs=* CclsMemberFunctionHierarchy call ccls#messages#member_hierarchy({'kind': 3}, <f-args>)
command! -nargs=* CclsMemberTypeHierarchy     call ccls#messages#member_hierarchy({'kind': 2}, <f-args>)

command! CclsBase                      call ccls#messages#inheritance(v:false)
command! CclsDerived                   call ccls#messages#inheritance(v:true)

command! -nargs=* CclsBaseHierarchy    call ccls#messages#inheritance_hierarchy(v:false, <f-args>)
command! -nargs=* CclsDerivedHierarchy call ccls#messages#inheritance_hierarchy(v:true, <f-args>)

command! CclsCallers                   call ccls#messages#calls(v:false)
command! CclsCallees                   call ccls#messages#calls(v:true)

command! -nargs=* CclsCallHierarchy    call ccls#messages#call_hierarchy(v:false, <f-args>)
command! -nargs=* CclsCalleeHierarchy  call ccls#messages#call_hierarchy(v:true, <f-args>)
