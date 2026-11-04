" Rex colorscheme for Neovim
" Maintainer: Antti Eskelinen
" License: MIT

" Neovim-only Lua colorscheme
if !has('nvim')
  echohl ErrorMsg
  echom "rex-theme.nvim requires Neovim"
  echohl None
  finish
endif

lua require('rex-theme').apply()
