vim-ccls: vim plugin for the ccls Language Server
===============================================================
[![Checks](https://github.com/m-pilia/vim-ccls/workflows/Checks/badge.svg)](https://github.com/m-pilia/vim-ccls/actions/workflows/checks.yml)
[![codecov](https://codecov.io/gh/m-pilia/vim-ccls/branch/master/graph/badge.svg)](https://codecov.io/gh/m-pilia/vim-ccls/branch/master)
[![License](https://img.shields.io/badge/License-MIT-blue.svg)](https://github.com/m-pilia/vim-ccls/blob/master/LICENSE)
![Docker hub](https://img.shields.io/docker/cloud/build/martinopilia/vim-ccls)

This plugin supports some additional methods provided by
[ccls](https://github.com/MaskRay/ccls), which are not part of the standard
Language Server Protocol (LSP). It does not implement a LSP client, but it
relies on an existing LSP plugin, adding on top of it the ccls-specific
features. Currently supported LSP clients are:

* [ALE](https://github.com/w0rp/ale)
* [coc.nvim](https://github.com/neoclide/coc.nvim)
* [LanguageClient-neovim](https://github.com/autozimu/LanguageClient-neovim)
* [nvim-lspconfig](https://github.com/neovim/nvim-lspconfig)
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

If you have not done it already,
[build](https://github.com/MaskRay/ccls/wiki/Build) and
[install](https://github.com/MaskRay/ccls/wiki/Install) ccls, and configure
your LSP client to use it (example instructions in the ccls wiki):
* [ALE](https://github.com/MaskRay/ccls/wiki/ALE)
* [coc.nvim](https://github.com/MaskRay/ccls/wiki/coc.nvim)
* [LanguageClient-neovim](https://github.com/MaskRay/ccls/wiki/LanguageClient-neovim)
* [nvim-lspconfig](https://github.com/neovim/nvim-lspconfig#ccls)
* [vim-lsc](https://github.com/MaskRay/ccls/wiki/vim-lsc)
* [vim-lsp](https://github.com/MaskRay/ccls/wiki/vim-lsp)

In order for ccls to work, make sure to correctly [set up your
project](https://github.com/MaskRay/ccls/wiki/Project-Setup), by either
providing a compilation database (`compile_commands.json`) or a `.ccls`
configuration file.

Commands
========

The plugin provides the following commands. Hierarchy commands will open a
tree-like buffer, while the other commands will populate the [quickfix
list](http://vimdoc.sourceforge.net/htmldoc/quickfix.html).

* **CclsBase**:
  Get a list of base classes for the symbol under the cursor.
* **CclsBaseHierarchy**:
  Get a tree of inheritance ancestors for the symbol under cursor.
* **CclsDerived**:
  Get a list of derived classes for the symbol under the cursor.
* **CclsDerivedHierarchy**:
  Get a tree of inheritance descendants for the symbol under cursor.
* **CclsCallers**:
  Get a list of functions calling the function under the cursor.
* **CclsCallHierarchy**:
  Get a hierarchy of functions calling the function under the cursor.
* **CclsCallees**:
  Get a list of functions called by the function under the cursor.
* **CclsCalleeHierahy**:
  Get a hierarchy of functions called by the function under the cursor.
* **CclsMembers**/**CclsMemberFunctions**/**CclsMemberTypes**:
  Get a lists of members for the symbol under cursor.
* **CclsMemberHierarchy**/**CclsMemberFunctionHierarchy**/**CclsMemberTypeHierarchy**:
  Get a tree of members for the symbol under cursor.
* **CclsVars**:
  Get a list of document variables.

Hierarchy commands accept an optional parameter `-float` to open the hierarchy
in a floating window instead of a split (Neovim only).

Settings
========

It is possible to automatically close a tree buffer when jumping to a location:
```vim
let g:ccls_close_on_jump = v:true
```

To control how many levels of depth in the sub-tree are fetched for each
request, when building a tree (a large value may make execution slow when
generating large trees):
```vim
let g:ccls_levels = 1
```

The size and position of the tree window can be set:
```vim
let g:ccls_size = 50
let g:ccls_position = 'botright'
let g:ccls_orientation = 'horizontal'
```

The size of the floating window (Neovim only) can be controlled:
```vim
let g:ccls_float_width = 50
let g:ccls_float_height = 20
```

The following `<Plug>` mappings are available to interact with a tree buffer:
```
<Plug>(yggdrasil-toggle-node)
<Plug>(yggdrasil-open-node)
<Plug>(yggdrasil-close-node)
<Plug>(yggdrasil-execute-node)
```

The default key bindings are:
```vim
nmap <silent> <buffer> o    <Plug>(yggdrasil-toggle-node)
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
let g:ccls_log_file = expand('~/my_log_file.txt')
```

License
=======

This software is distributed under the MIT license. The full text of the license
is available in the [LICENSE
file](https://github.com/m-pilia/vim-ccls/blob/master/LICENSE) distributed
alongside the source code.
