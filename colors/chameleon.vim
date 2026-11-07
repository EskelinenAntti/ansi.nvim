" Chameleon colorscheme for Neovim
" Maintainer: Antti Eskelinen
" License: MIT

" Neovim-only Lua colorscheme
if !has('nvim')
  echohl ErrorMsg
  echom "chameleon.nvim requires Neovim"
  echohl None
  finish
endif

lua require('chameleon').apply()
