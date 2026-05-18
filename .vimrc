call plug#begin('~/.vim/plugged')
  Plug 'prabirshrestha/vim-lsp'
  Plug 'mattn/vim-lsp-settings'
  Plug 'fatih/vim-go', { 'do': ':GoUpdateBinaries' }

  " UI
  Plug 'ghifarit53/tokyonight-vim'
  Plug 'vim-airline/vim-airline'
  Plug 'vim-airline/vim-airline-themes'
  Plug 'ryanoasis/vim-devicons'
call plug#end()

" --- Appearance ---
if has('termguicolors')
  set termguicolors
endif

set guifont=JetBrainsMono\ Nerd\ Font\ 12

set background=dark
let g:tokyonight_style = 'night'
let g:tokyonight_enable_italic = 1
silent! colorscheme tokyonight

" Tone down the vibrant light-blues
augroup tokyonight_tweaks
  autocmd!
  autocmd ColorScheme tokyonight call s:mute_blues()
augroup END
function! s:mute_blues() abort
  " Functions: #7aa2f7 -> muted slate-blue
  highlight Function     guifg=#8aa0c4
  highlight Identifier   guifg=#8aa0c4
  " Types / cyan-ish: #2ac3de / #7dcfff -> softer steel
  highlight Type         guifg=#90b4c2
  highlight Special      guifg=#90b4c2
  " Keywords (purple-blue) keep, but mute Constant blue
  highlight Constant     guifg=#a8b5d1
endfunction
call s:mute_blues()

" Airline with powerline + nerd font glyphs
let g:airline_powerline_fonts = 1
let g:airline_theme = 'tokyonight'
let g:airline#extensions#tabline#enabled = 1
let g:webdevicons_enable_airline_statusline = 1

" Hide '~' end-of-buffer fillers, nicer vertical split
set fillchars=eob:\ ,vert:│,fold:·

" --- LSP signs with nerd font glyphs (replaces E>, W>, A>, etc.) ---
let g:lsp_diagnostics_signs_error       = {'text': ""}
let g:lsp_diagnostics_signs_warning     = {'text': ""}
let g:lsp_diagnostics_signs_information = {'text': ""}
let g:lsp_diagnostics_signs_hint        = {'text': ""}

" --- LSP / go config ---
let g:lsp_format_sync_timeout = 1000
let g:lsp_document_symbols_enabled = 0
let g:go_def_mapping_enabled = 0
let g:go_doc_keywordprg_enabled = 0
let g:go_fmt_command = 'goimports'

function! s:on_lsp_buffer_enabled() abort
  setlocal omnifunc=lsp#complete
  setlocal signcolumn=yes
  nmap <buffer> gd <plug>(lsp-definition)
  nmap <buffer> gr <plug>(lsp-references)
  nmap <buffer> gi <plug>(lsp-implementation)
  nmap <buffer> K  <plug>(lsp-hover)
endfunction

augroup lsp_install
  au!
  autocmd User lsp_buffer_enabled call s:on_lsp_buffer_enabled()
augroup END
