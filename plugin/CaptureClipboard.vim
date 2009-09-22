" CaptureClipboard.vim: Append system clipboard changes to current buffer. 
"
" Maintainer:	Marian Csontos
" REVISION	DATE		REMARKS 
"	002	23-Sep-2009	Renamed from TrackClipboard to CaptureClipboard. 
"				ENH: Directly updating the window after each
"				capture, not every 5s. 
"				ENH: Capture is inserted below current line, not
"				necessarily at the end of the buffer. 
"				BUG: Remove the EOF marker, or else the capture
"				won't even start. 
"				BUG: Silently ignoring autosave failures, the
"				user can deal with them after capturing is
"				finished. 
"				ENH: Checking for 'nomodifiable' buffer. 
"	001	26-Oct-2006	file creation from vimtip #1370

" Avoid installing twice or when in compatible mode
if exists('g:loaded_CaptureClipboard')
    finish
endif
let g:loaded_CaptureClipboard = 1

function! s:Message()
    echo 'Appending clipboard changes to current buffer. To stop, press <CTRL-C> or copy "EOF". '
endfunction

function! s:CaptureClipboard(...)
    if ! &l:modifiable
	let v:errmsg = "E21: Cannot make changes, 'modifiable' is off"
	echohl ErrorMsg
	echomsg v:errmsg
	echohl None
	return
    endif

    let l:delimiter = (a:0 ? a:1 : '')
    call s:Message()

    if @* ==# 'EOF'
	" Remove the EOF marker (from a previous :CaptureClipboard run) from the
	" clipboard, or else the capture won't even start. 
	let @* = ''
    endif

    let l:temp = @*
    while @* !=# 'EOF'
	if l:temp !=# @*
	    let l:temp = @*
	    if ! empty( l:delimiter )
		put =l:delimiter
	    endif
	    put =l:temp

	    try
		write
	    catch /^Vim\%((\a\+)\)\=:E/
		" Writing the buffer may fail for several reasons: E32: No file
		" name, E45: 'readonly' is set, disk full, ...
		" We silently ignore these problems during capturing; the user
		" can deal with this after capturing is finished. 
	    endtry

	    redraw
	    call s:Message()
	else
	    sleep 50ms
	endif
    endwhile
    echo 'Appending of clipboard changes done.' 
endfunction 

command! -nargs=? CaptureClipboard call <SID>CaptureClipboard(<f-args>)

