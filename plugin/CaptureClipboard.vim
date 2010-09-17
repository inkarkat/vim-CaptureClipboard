" CaptureClipboard.vim: Append system clipboard changes to current buffer. 
"
" DESCRIPTION:
" USAGE:
":[count]CaptureClipboard[!] [{delimiter}]
":[count]CaptureClipboardReverse[!] [{delimiter}]
"			Monitors the clipboard for changes and inserts any
"			change of clipboard contents into the current buffer (in
"			new lines, optionally delimited by {delimiter}). 
"			To stop, press <CTRL-C> or copy "EOF". If [count] is
"			given, the capture stops after [count] captures. 
"
"			If [!] is given, whitespace (including new lines) is
"			trimmed from the beginning and end of each capture. 
"			Use :$|CaptureClipboard to append at the end of the
"			current buffer. 
"			With :CaptureClipboardReverse, changes are prepended,
"			reverting the insertion order. Normally, changes are
"			appended to the current or given [line].
"
"			{delimiter} is evaluated as an expression if it is
"			(single- or double-)quoted, or contains backslashes. 
"			The default {delimiter} is "\n"; each capture is placed
"			on a new line. Use '' to place everything next to each
"			other, ' ' to put a space character in between, "\n--\n"
"			to insert a -- separator line between captures. When
"			{delimiter} contains a newline character, the first
"			capture will already start on a new line. 
"
" INSTALLATION:
"   Put the script into your user or system Vim plugin directory (e.g.
"   ~/.vim/plugin). 

" DEPENDENCIES:
"   - Requires Vim 7.0 or higher. 

" CONFIGURATION:
" INTEGRATION:
" LIMITATIONS:
" ASSUMPTIONS:
" KNOWN PROBLEMS:
" TODO:
"
" Copyright: (C) 2010 by Ingo Karkat
"   The VIM LICENSE applies to this script; see ':help copyright'. 
"
" Original Autor: Marian Csontos
" Maintainer:	Ingo Karkat <ingo@karkat.de> 
"
" REVISION	DATE		REMARKS 
"	005	17-Sep-2010	ENH: Insertion of newline is now entirely
"				controlled by {separator}, not by
"				:0CaptureClipboard. 
"				ENH: [bang] now turns on trimming of whitespace,
"				(seldomly used) prepending is now separate
"				:CaptureClipboardReverse command. 
"				ENH: {separator} is not inserted before first
"				capture, only between subsequent ones. 
"				ENH: Can limit number of captures via [count]. 
"	004	26-Feb-2010	Now using correct plural for the title message. 
"	003	24-Feb-2010	ENH: Showing capture status in 'titlestring' to
"				indicate the blocking polling mode and also any
"				successful capture even when Vim is minimized or
"				the messages are otherwise obscured by another
"				window. 
"	002	23-Sep-2009	Renamed from TrackClipboard to CaptureClipboard. 
"				ENH: Directly updating the window after each
"				capture, not every 5s. 
"				ENH: Capture is inserted below current line, not
"				necessarily at the end of the buffer. 
"				ENH: <bang> can be used to revert insertion, and
"				prepend instead of appending. (Analog to the
"				:put command.) 
"				BUG: Remove the EOF marker, or else the capture
"				won't even start. 
"				BUG: Silently ignoring autosave failures, the
"				user can deal with them after capturing is
"				finished. 
"				ENH: Checking for 'nomodifiable' buffer. 
"				ENH: Progress and end messages list number of
"				captures. 
"				ENH: Allowing empty line delimiter by passing in
"				'' or "". Evaluating quoted arguments to allow
"				whitespace and other special stuff in delimiter. 
"				ENH: Insertion without newlines, all in one
"				line. 
"	001	26-Oct-2006	file creation from vimtip #1370

" Avoid installing twice or when in unsupported Vim version. 
if exists('g:loaded_CaptureClipboard') || (v:version < 700)
    finish
endif
let g:loaded_CaptureClipboard = 1

let s:save_cpo = &cpo
set cpo&vim

function! s:Message( ... )
    if &title
	if ! a:0
	    " Initial invocation: Save original title and set up autocmd to
	    " restore it in case the capturing is not stopped via "EOF", but by
	    " aborting the command. 
	    let s:save_titlestring = &titlestring
	    augroup CaptureClipboard
		au!
		" Note: The CursorMoved event is triggered immediately after a
		" CTRL-C if text has been inserted; the other events are not
		" triggered inside the loop. If no text has been captured, we
		" try to restore the title when the cursor moves or the window
		" changes. 
		au CursorHold,CursorMoved,WinLeave * let &titlestring = s:save_titlestring | autocmd! CaptureClipboard
	    augroup END
	endif

	let &titlestring = (a:0 ? a:1 . printf(' clip%s...', (a:1 == 1 ? '' : 's')) : 'Capturing...') . ' - %{v:servername}'
	redraw  " This is necessary to update the title. 
    endif

    echo printf('Capturing clipboard changes %sto current buffer. To stop, press <CTRL-C> or copy "EOF". ', (a:0 ? '(' . a:1 . ') ' : ''))
endfunction
function! s:EndMessage( count )
    redraw
    echo printf('Captured %s clipboard changes. ', (a:count > 0 ? a:count : 'no'))

    if &title
	autocmd! CaptureClipboard
	let &titlestring = s:save_titlestring
	unlet s:save_titlestring
    endif
endfunction

function! s:GetDelimiter( argument )
    try
	if a:argument =~# '^\([''"]\).*\1$' 
	    " The argument is quotes, evaluate it. 
	    execute 'let l:delimiter =' a:argument
	elseif a:argument =~# '\\' 
	    " The argument contains escape characters, evaluate them. 
	    execute 'let l:delimiter = "' . a:argument . '"'
	else
	    let l:delimiter = a:argument
	endif
    catch /^Vim\%((\a\+)\)\=:E/
	let l:delimiter = a:argument
    endtry
    return l:delimiter
endfunction
function! s:Insert( text, delimiter, isPrepend )
    let l:insertText = (a:isPrepend ? a:text . a:delimiter : a:delimiter . a:text)
    if l:insertText =~# (a:isPrepend ? '\n$' : '^\n')
	let l:insertText = (a:isPrepend ? strpart(l:insertText, 0, strlen(l:insertText) - 1) : strpart(l:insertText, 1))
	execute 'put' . (a:isPrepend ? '!' : '') '=l:insertText'
    else
	execute "normal! \"=l:insertText\<CR>" . (a:isPrepend ? 'Pg`[' : 'pg`]')
    endif
endfunction
function! s:CaptureClipboard( isPrepend, isTrim, count, ... )
    if ! &l:modifiable
	let v:errmsg = "E21: Cannot make changes, 'modifiable' is off"
	echohl ErrorMsg
	echomsg v:errmsg
	echohl None
	return
    endif

    let l:delimiter = (a:0 ? s:GetDelimiter(a:1) : "\n")
    let l:firstDelimiter = (l:delimiter =~# '\n' ? "\n" : '')

    call s:Message()
    let l:captureCount = 0

    if @* ==# 'EOF'
	" Remove the EOF marker (from a previous :CaptureClipboard run) from the
	" clipboard, or else the capture won't even start. 
	let @* = ''
    endif

    let l:temp = @*
    while ! (@* ==# 'EOF' || (a:count && l:captureCount == a:count))
	if l:temp !=# @*
	    let l:temp = @*
	    call s:Insert(
	    \	(a:isTrim ? substitute(l:temp, '^\_s*\(.\{-}\)\_s*$', '\1', 'g') : l:temp),
	    \	(l:captureCount == 0 ? l:firstDelimiter : l:delimiter),
	    \	a:isPrepend
	    \)
	    let l:captureCount += 1

	    silent! write
	    redraw
	    call s:Message(l:captureCount)
	else
	    sleep 50ms
	endif
    endwhile

    call s:EndMessage(l:captureCount)
endfunction 

command! -bang -count -nargs=? CaptureClipboard		call <SID>CaptureClipboard(0, <bang>0, <count>, <f-args>)
command! -bang -count -nargs=? CaptureClipboardReverse	call <SID>CaptureClipboard(1, <bang>0, <count>, <f-args>)

let &cpo = s:save_cpo
unlet s:save_cpo
" vim: set sts=4 sw=4 noexpandtab ff=unix fdm=syntax :
