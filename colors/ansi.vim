" ANSI colorscheme for Neovim
" Maintainer: Antti Eskelinen
" License: MIT

" Neovim-only Lua colorscheme
if !has('nvim')
  echohl ErrorMsg
  echom "ansi.nvim requires Neovim"
  echohl None
  finish
endif

lua require('ansi').apply()
