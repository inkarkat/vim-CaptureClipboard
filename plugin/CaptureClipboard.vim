" CaptureClipboard.vim: Append system clipboard changes to current buffer.

" DEPENDENCIES:
"   - Requires Vim 7.0 or higher.
"   - ingo-library.vim plugin

" Copyright: (C) 2010-2019 Ingo Karkat
"   The VIM LICENSE applies to this script; see ':help copyright'.
"
" Original Autor: Marian Csontos
" Maintainer:	Ingo Karkat <ingo@karkat.de>

" Avoid installing twice or when in unsupported Vim version.
if exists('g:loaded_CaptureClipboard') || (v:version < 700)
    finish
endif
let g:loaded_CaptureClipboard = 1

"- configuration --------------------------------------------------------------

if ! exists('g:CaptureClipboard_DefaultDelimiter')
    let g:CaptureClipboard_DefaultDelimiter = "\n"
endif

if ! exists('g:CaptureClipboard_EndOfCaptureMarker')
    let g:CaptureClipboard_EndOfCaptureMarker = '.'
endif

if ! exists('g:CaptureClipboard_IsAutoSave')
    let g:CaptureClipboard_IsAutoSave = 0
endif

if ! exists('g:CaptureClipboard_Register')
    let g:CaptureClipboard_Register = (ingo#os#IsWindows() ? '*' : '+')
endif


"- commands -------------------------------------------------------------------

command! -bang -count -nargs=? CaptureClipboard		call setline('.', getline('.')) | if ! CaptureClipboard#CaptureClipboard(g:CaptureClipboard_Register, 0, <bang>0, <count>, <f-args>) | echoerr ingo#err#Get() | endif
command! -bang -count -nargs=? CaptureClipboardReverse	call setline('.', getline('.')) | if ! CaptureClipboard#CaptureClipboard(g:CaptureClipboard_Register, 1, <bang>0, <count>, <f-args>) | echoerr ingo#err#Get() | endif

if ! ingo#os#IsWindows()
command! -bang -count -nargs=? CaptureSelection		call setline('.', getline('.')) | if ! CaptureClipboard#CaptureClipboard('*'                        , 0, <bang>0, <count>, <f-args>) | echoerr ingo#err#Get() | endif
command! -bang -count -nargs=? CaptureSelectionReverse	call setline('.', getline('.')) | if ! CaptureClipboard#CaptureClipboard('*'                        , 1, <bang>0, <count>, <f-args>) | echoerr ingo#err#Get() | endif
endif


"- mappings --------------------------------------------------------------------

inoremap <silent> <Plug>(CaptureClipboardInsertOne) x<BS><C-\><C-n>:1CaptureClipboard ""<CR>a
if ! hasmapto('<Plug>(CaptureClipboardInsertOne)', 'i')
    imap <C-R>? <Plug>(CaptureClipboardInsertOne)
endif

" vim: set ts=8 sts=4 sw=4 noexpandtab ff=unix fdm=syntax :
