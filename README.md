vim-lsp-ccls: vim plugin for the ccls Language Server
===============================================================
[![Travis CI Build Status](https://travis-ci.org/m-pilia/vim-lsp-ccls.svg?branch=master)](https://travis-ci.org/m-pilia/vim-lsp-ccls)
[![codecov](https://codecov.io/gh/m-pilia/vim-lsp-ccls/branch/master/graph/badge.svg)](https://codecov.io/gh/m-pilia/vim-lsp-ccls/branch/master)
[![License](https://img.shields.io/badge/License-MIT-blue.svg)](https://github.com/m-pilia/vim-lsp-ccls/blob/master/LICENSE)

This plugin supports some additional methods provided by
[ccls](https://github.com/MaskRay/ccls), which are not part of the standard
Language Server Protocol (LSP). It does not implement a LSP client, but it
relies on an existing LSP plugin, adding on top of it the ccls-specific
features. Currently supported LSP clients are:

* [coc.nvim](https://github.com/neoclide/coc.nvim)
* [LanguageClient-neovim](https://github.com/autozimu/LanguageClient-neovim)
* [vim-lsc](https://github.com/natebosch/vim-lsc)
* [vim-lsp](https://github.com/prabirshrestha/vim-lsp)

The plugin implements a tree viewer to display call, inheritance, and member
hierarchies. Trees are built lazily, fetching children only when it is needed
to expand a sub-tree, allowing to handle large trees.

The call hierarchy allows to visualise a tree of functions calling the function
under the cursor (analogous to the Call Hierarchy View in Eclipse). Similarly,
the callee tree visualises a hierarchy in the opposite direction, showing
functions being called.

The base/derived hierarchy allows to visualise inheritance trees for the class
under the cursor.

The member hierarchy allows to visualise a tree of members inside a type under
the cursor.

![demo](https://user-images.githubusercontent.com/8300317/56425740-e14c7e00-62b5-11e9-8b83-d1d064fc3033.gif)

Installation
============

This plugin can be installed with any vim plugin manager. One of the supported
Language Server clients listed above needs to be installed and properly
configured with ccls as language server in order for it to work.

To install ccls and set up a project to use it in combination with vim-lsp or
LanguageClient-neovim, follow the instructions in the ccls wiki:
* [coc.nvim](https://github.com/MaskRay/ccls/wiki/coc.nvim)
* [LanguageClient-neovim](https://github.com/MaskRay/ccls/wiki/LanguageClient-neovim)
* [vim-lsp](https://github.com/MaskRay/ccls/wiki/vim-lsp)

To set up a project with vim-lsc, please refer to the [lsc
documentation](https://github.com/natebosch/vim-lsc/blob/master/doc/lsc.txt).

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
let g:lsp_ccls_close_on_jump = v:true
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
logging, by setting the following variable:

```vim
let g:lsp_ccls_log_file = expand('~/my_log_file.txt')
```

License
=======

This software is distributed under the MIT license. The full text of the license
is available in the [LICENSE
file](https://github.com/m-pilia/vim-lsp-ccls/blob/master/LICENSE) distributed
alongside the source code.
