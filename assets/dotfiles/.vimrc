" Kevin Jayne (kevin.jayne@icloud.com) vim configuration file

" For all text files set 'textwidth' to 78 characters.
autocmd FileType text setlocal textwidth=78

" Search Configuration
set ignorecase          " Case Insensitivity
set smartcase           " Unless explicit match
set incsearch           " Highlight Matching as I type
set hlsearch            " Highlight Matches

" Other Settings
set updatetime=100        " Mainly for git gutter update
set expandtab             " Use spaces instead of tabs
set title                 " Set the terminal title
set autoindent            " Enable auto-indenting on new lines
set copyindent            " Copy previous indenting
set tabstop=2             " Number of spaces that a <Tab> in the file counts for
set shiftwidth=2          " Number of spaces to use for each step of (auto)indent
set laststatus=2          " Always display the status line
set hidden                " Allow hiding buffers with unsaved changes
set paste                 " (Consider removing or toggling as needed)
set number                " Show line numbers
set background=dark       " Set background to dark
set backspace=indent,eol,start " Set backspace behavior

" Force Defaults to UTF-8
set encoding=utf-8
" set fileencoding=utf-8  " Removed or moved to autocmd

" Set fileencoding via autocmd
augroup set_fileencoding
  autocmd!
  autocmd BufRead,BufNewFile * setlocal fileencoding=utf-8
augroup END

" Enable Mouse Support with SGR (xterm 1006 mouse support for more lines)
set mouse+=a
if !has('nvim')
  set ttymouse=xterm2
endif

" VIM-Markdown Configuration
let g:vim_markdown_folding_disabled=1

" Syntax Highlighting and Filetype Settings
syntax on
au BufNewFile,BufRead Jenkinsfile setf groovy

" Clipboard Settings (Commented Out)
" set clipboard=unnamedplus
" yank to clipboard
" requires: 
"    brew install reattach-to-user-namespace 
"    brew install vim --with-client-server
" if has("clipboard")
  " set clipboard=unnamed " copy to the system clipboard

  " if has("unnamedplus") " X11 support
    " set clipboard+=unnamedplus
  " endif
" endif

" Set autoreading to on
set autoread
au CursorHold * checktime

" Install vim-plug if not installed
if empty(glob('~/.vim/autoload/plug.vim'))
  silent !curl -fLo ~/.vim/autoload/plug.vim --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
  autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
endif

" Specify a directory for plugins
call plug#begin('~/.vim/plugged')

" On-demand loading
Plug 'nathanaelkane/vim-indent-guides'
Plug 'scrooloose/nerdtree', { 'on':  'NERDTreeToggle' }
Plug 'scrooloose/nerdcommenter'
Plug 'airblade/vim-gitgutter'
Plug 'bling/vim-airline'
Plug 'flazz/vim-colorschemes'
Plug 'scrooloose/syntastic'

call plug#end()

" Colors
" colorscheme iceberg
" colorscheme molokai
" colorscheme dracula

" NERDTree Settings
let g:NERDTreeMouseMode=3
let g:NERDTreeWinSize=25
let NERDTreeShowHidden=1           " Show hidden files
map <C-n> :NERDTreeToggle<CR>      " Open NERDTree with Ctrl+n 

" Open NERDTree in new tabs and windows if no command line args set
" NERDTree is e.g., not helpful if you do a git commit or something similar.
autocmd VimEnter * if !argc() | NERDTree | endif

" Exit Vim when editor closed and NERDTree is the only window open
autocmd bufenter * if (winnr("$") == 1 && exists("b:NERDTree") && b:NERDTree.isTabTree()) | q | endif

" Indent Guides Settings
let g:indent_guides_enable_on_vim_startup = 1
set ts=4 sw=4 et
let g:indent_guides_start_level = 2
let g:indent_guides_guide_size = 1 

" Toggle Line Numbers
function! NumberToggle()
  if &number
    set nonumber
    set norelativenumber
  else
    set number
    " set relativenumber
  endif
endfunction
map <C-m> :call NumberToggle()<CR>

" Autocommand Group for Additional Settings
augroup vimrcEx
  autocmd!
  
  " When editing a file, always jump to the last known cursor position.
  " Don't do it when the position is invalid or when inside an event handler
  " (happens when dropping a file on gvim).
  " Also don't do it when the mark is in the first line, that is the default
  " position when opening a file.
  " autocmd BufReadPost *
  "   \ if line("'\"") > 1 && line("'\"") <= line("$") |
  "   \   exe "normal! g`\"" |
  "   \ endif
augroup END
