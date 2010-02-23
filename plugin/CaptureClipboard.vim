" CaptureClipboard.vim: Append system clipboard changes to current buffer. 
"
" DESCRIPTION:
" USAGE:
":[line]CaptureClipboard[!] [{delimiter}]
"			Monitors the clipboard for changes and inserts any
"			change of clipboard contents into the current buffer (in
"			new lines, optionally delimited by {delimiter}). 
"			If [!] is given, changes are prepended, reverting the
"			insertion order. Normally, changes are appended after
"			the current line or given [line].
"			Use :$CaptureClipboard to append at the end of the
"			current buffer. 
"			Use :CaptureClipboard "" to insert an empty line between
"			captures. 
"			Use :0CaptureClipboard to capture everything to the same
"			(current) line, without inserting newline characters. 
"			To stop, press <CTRL-C> or copy "EOF". 
"
"			{delimiter} is evaluated as an expression if it is
"			(single- or double-)quoted, or contains backslashes. 
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
" Copyright: (C) 2009 by Ingo Karkat
"   The VIM LICENSE applies to this script; see ':help copyright'. 
"
" Original Autor: Marian Csontos
" Maintainer:	Ingo Karkat <ingo@karkat.de> 
"
" REVISION	DATE		REMARKS 
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

function! s:Message( ... )
    echo printf('Capturing clipboard changes %sto current buffer. To stop, press <CTRL-C> or copy "EOF". ', (a:0 ? '(' . a:1 . ') ' : ''))
endfunction
function! s:EndMessage( count )
    redraw
    echo printf('Captured %s clipboard changes. ', (a:count > 0 ? a:count : 'no'))
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
function! s:Insert( text, isPrepend, isSameLine )
    if a:isSameLine
	execute "normal! \"=a:text\<CR>" . (a:isPrepend ? 'Pg`[' : 'pg`]')
    else
	execute 'put' . (a:isPrepend ? '!' : '') '=a:text'
    endif
endfunction
function! s:CaptureClipboard( isPrepend, count, ... )
    if ! &l:modifiable
	let v:errmsg = "E21: Cannot make changes, 'modifiable' is off"
	echohl ErrorMsg
	echomsg v:errmsg
	echohl None
	return
    endif

    let l:isSameLine = (a:count == 0)

    if a:count > 0
	" Go to specified line number. (Will probably mostly used with
	" :$CaptureClipboard to append to the end of the buffer.) 
	execute a:count
    endif

    if a:0
	let l:delimiter = s:GetDelimiter(a:1)
    endif

    call s:Message()
    let l:captureCount = 0

    if @* ==# 'EOF'
	" Remove the EOF marker (from a previous :CaptureClipboard run) from the
	" clipboard, or else the capture won't even start. 
	let @* = ''
    endif

    let l:temp = @*
    while @* !=# 'EOF'
	if l:temp !=# @*
	    let l:temp = @*
	    if exists('l:delimiter')
		call s:Insert(l:delimiter, a:isPrepend, l:isSameLine)
	    endif
	    call s:Insert(l:temp, a:isPrepend, l:isSameLine)
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

command! -bang -range=-1 -nargs=? CaptureClipboard call <SID>CaptureClipboard(<bang>0, <count>, <f-args>)

