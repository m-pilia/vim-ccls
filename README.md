vim-lsp-ccls: Extension of vim-lsp for the ccls Language Server
===============================================================
[![Travis CI Build Status](https://travis-ci.org/m-pilia/vim-lsp-ccls.svg?branch=master)](https://travis-ci.org/m-pilia/vim-lsp-ccls)

This plugin is an extension of
[vim-lsp](https://github.com/prabirshrestha/vim-lsp) that adds support for some
additional methods provided by [ccls](https://github.com/MaskRay/ccls), which
are not part of the standard Language Server Protocol.

The plugin implements a tree viewer to display call, inheritance, and member
hierarchies. Trees are built lazily, fetching children only when it is needed
to expand a sub-tree, allowing to handle large trees.

The call hierarchy allows to visualise a tree of functions calling the function
under the cursor (analogous to the Call Hierarchy View in Eclipse). Similarly,
the callee tree visualises a hierarchy in the opposite direction, showing
functions being called.

![call_hierarchy](https://user-images.githubusercontent.com/8300317/54882558-80b75600-4e5b-11e9-8e02-6d17529df4fa.png)

The base/derived hierarchy allows to visualise inheritance trees for the class
under the cursor.

![inheritance_hierarchy](https://user-images.githubusercontent.com/8300317/54882559-80b75600-4e5b-11e9-9a68-12f98d8f2f5c.png)

The member hierarchy allows to visualise a tree of members inside a type under
the cursor.

![member_hierarchy](https://user-images.githubusercontent.com/8300317/54882560-80b75600-4e5b-11e9-95ef-8725f6eba410.png)

Installation
============

This plugin can be installed with any vim plugin manager. It depends on
[vim-lsp](https://github.com/prabirshrestha/vim-lsp), that needs to be installed
in order for it to work.

To install ccls and set up a project to use it in combination with vim-lsp,
follow the instructions in the [ccls
wiki](https://github.com/MaskRay/ccls/wiki/vim-lsp).

Commands
========

The plugin provides the following commands. Hierarchy commands will open a
tree-like buffer, while the other commands will populate the [quickfix
list](http://vimdoc.sourceforge.net/htmldoc/quickfix.html).

* **LspCclsBase**:
  Get a list of base classes for the symbol under the cursor.
* **LspCclsBaseHierarchy**:
  Get a tree of inheritance ancestors for the symbol under cursor.
* **LspCclsDerived**:
  Get a list of derived classes for the symbol under the cursor.
* **LspCclsDerivedHierarchy**:
  Get a tree of inheritance descendants for the symbol under cursor.
* **LspCclsCallers**:
  Get a list of functions calling the function under the cursor.
* **LspCclsCallHierarchy**:
  Get a hierarchy of functions calling the function under the cursor.
* **LspCclsCallees**:
  Get a list of functions called by the function under the cursor.
* **LspCclsCalleeHierahy**:
  Get a hierarchy of functions called by the function under the cursor.
* **LspCclsMembers**:
  Get a lists of members for the symbol under cursor.
* **LspCclsMemberHierarchy**:
  Get a tree of members for the symbol under cursor.
* **LspCclsVars**:
  Get a list of document variables.

Settings
========

It is possible to automatically close a tree buffer when jumping to a location:
```vim
let g:lsp_ccls_close_on_jump = v:false
```

To control how many levels of depth in the sub-tree are fetched for each
request, when building a tree (a large value may make execution slow when
generating large trees):
```vim
let g:lsp_ccls_levels = 1
```

The size and position of the tree window can be set:
```vim
let g:lsp_ccls_size = 50
let g:lsp_ccls_position = 'botright'
let g:lsp_ccls_orientation = 'horizontal'
```

The following `<Plug>` mappings are available to interact with a tree buffer:
```
<Plug>(yggdrasil-toggle-node)
<Plug>(yggdrasil-open-node)
<Plug>(yggdrasil-close-node)
<Plug>(yggdrasil-open-subtree)
<Plug>(yggdrasil-close-subtree)
<Plug>(yggdrasil-execute-node)
```

The default key bindings are:
```vim
nmap <silent> <buffer> o    <Plug>(yggdrasil-toggle-node)
nmap <silent> <buffer> O    <Plug>(yggdrasil-open-subtree)
nmap <silent> <buffer> C    <Plug>(yggdrasil-close-subtree)
nmap <silent> <buffer> <cr> <Plug>(yggdrasil-execute-node)
nnoremap <silent> <buffer> q :q<cr>
```

They can be disabled and replaced with custom mappings:
```vim
let g:yggdrasil_no_default_maps = 1
au FileType yggdrasil nmap <silent> <buffer> o <Plug>(yggdrasil-toggle-node)
```

Debugging
=========

If you encounter any problem, the first step for troubleshooting is to enable
logging of `vim-lsp`, to get debug information in a log file:

```vim
let g:lsp_log_verbose = 1
let g:lsp_log_file = expand('~/vim-lsp.log')
```

License
=======

This software is distributed under the MIT license. The full text of the license
is available in the [LICENSE
file](https://github.com/m-pilia/vim-lsp-ccls/blob/master/LICENSE) distributed
alongside the source code.
