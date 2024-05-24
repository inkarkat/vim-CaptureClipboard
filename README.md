CAPTURE CLIPBOARD
===============================================================================
_by Ingo Karkat_
_(original version by Marian Csontos)_

DESCRIPTION
------------------------------------------------------------------------------

Quotes or text fragments can be collected from various sources outside Vim
into a single text document through the clipboard. This plugin makes
consecutive copy-and-pastes into Vim much more comfortable by monitoring the
system clipboard for changes and appending them into the current Vim buffer
automatically. Feedback about the number of captures is given in Vim's window
title, so one does not have to switch back and forth between applications any
more, and can completely focus on text collection via CTRL-C, CTRL-C, ...

USAGE
------------------------------------------------------------------------------

    :[count]CaptureClipboard[!] {delimiter}
    :[count]CaptureClipboard[!] {prefix}^M{suffix}
    :[count]CaptureClipboard[!] {prefix}^M{delimiter}^M{suffix}
    :[count]CaptureClipboard[!] {first-prefix}^M{prefix}^M{delimiter}^M{suffix}
    :[count]CaptureClipboardReverse[!] {...}
                            Monitors the clipboard for changes and inserts any
                            change of clipboard contents into the current buffer
                            (in new lines, or, if given, delimited by {delimiter},
                            and with {prefix} before and {suffix} after).
                            To stop, press <CTRL-C> or copy a literal dot (".") to
                            the clipboard. If [count] is given, the capture stops
                            after [count] captures.

                            If [!] is given, whitespace (including new lines) is
                            trimmed from the beginning and end of each capture.

                            With :CaptureClipboardReverse, changes are prepended,
                            reverting the insertion order. Normally, changes are
                            appended to the current or given [line].
                            Use :$|CaptureClipboard to append to the end of the
                            current buffer.

                            {delimiter} is evaluated as an expression if it is
                            (single- or double-) quoted, or contains backslashes.
                            The default {delimiter} is "\n"; each capture is
                            placed on a new line. Use '' to place everything next
                            to each other, ' ' to put a space character in
                            between, "\n--\n" to insert a -- separator line
                            between captures. When {delimiter} contains a newline
                            character, the first capture will already start on a
                            new line.
                            Backslash-escaped characters (like \n) are also
                            supported in {prefix} and {suffix}.
    :CaptureSelection [...] Variant (on Linux) that uses the selection
                            (quotestar) instead of the system clipboard.

    CTRL-R ?                Wait for one capture from the clipboard and insert it
                            at the current cursor position.

INSTALLATION
------------------------------------------------------------------------------

The code is hosted in a Git repo at
    https://github.com/inkarkat/vim-CaptureClipboard
You can use your favorite plugin manager, or "git clone" into a directory used
for Vim packages. Releases are on the "stable" branch, the latest unstable
development snapshot on "master".

This script is also packaged as a vimball. If you have the "gunzip"
decompressor in your PATH, simply edit the \*.vmb.gz package in Vim; otherwise,
decompress the archive first, e.g. using WinZip. Inside Vim, install by
sourcing the vimball or via the :UseVimball command.

    vim CaptureClipboard*.vmb.gz
    :so %

To uninstall, use the :RmVimball command.

### DEPENDENCIES

- Requires Vim 7.0 or higher.
- Requires the ingo-library.vim plugin ([vimscript #4433](http://www.vim.org/scripts/script.php?script_id=4433)), version 1.024 or
  higher.

CONFIGURATION
------------------------------------------------------------------------------

For a permanent configuration, put the following commands into your vimrc:

By default, each capture will be placed on a new line in the capture buffer;
i.e. the delimiter between captures is a newline character:

    let g:CaptureClipboard_DefaultDelimiter = "\n"

The marker text that will stop capturing can be changed via:

    let g:CaptureClipboard_EndOfCaptureMarker = '.'

If you capture a lot of text or the captured information is very valuable, you
can automatically persist the capture buffer after each capture. Enable via:

    let g:CaptureClipboard_IsAutoSave = 1

In X, changes to the current selection (quotestar) are captured. If you want
to only capture changes to the X clipboard (quoteplus), not every change in
selection, use:

    let g:CaptureClipboard_Register = '+'

If you want to use a different mapping, map your keys to the
&lt;Plug&gt;(CaptureClipboardInsertOne) mapping target _before_ sourcing the script
(e.g. in your vimrc):

    imap <C-R>? <Plug>(CaptureClipboardInsertOne)

CONTRIBUTING
------------------------------------------------------------------------------

Report any bugs, send patches, or suggest features via the issue tracker at
https://github.com/inkarkat/vim-CaptureClipboard/issues or email (address
below).

HISTORY
------------------------------------------------------------------------------

##### 1.22    RELEASEME
- Suppress paste messages, no duplicate :redraw

##### 1.21    19-May-2019
- Default to "+ on Linux; add :CaptureSelection variant for "\* there.

##### 1.20    23-Apr-2015
- Use ingo#lines#PutWrapper() to avoid clobbering the expression register.
- ENH: Support {prefix}^M{suffix} and
  {first-prefix}^M{prefix}^M{delimiter}^M{suffix} alternatives to the
  simplistic {delimiter}.

__You need to separately install ingo-library ([vimscript #4433](http://www.vim.org/scripts/script.php?script_id=4433)) version
  1.024 (or higher)!__

##### 1.11    30-Dec-2012
- Implement check for no-modifiable buffer via noop-modification instead of
checking for 'modifiable'; this also handles the read-only warning.

##### 1.10    29-Oct-2012
- Add mapping to wait for and insert one capture.

##### 1.00    20-Sep-2010
- First published version.

##### 0.01    23-Sep-2009
- First enhancements.

##### 0.00    26-Oct-2006
- Copied original function TrackClipboard() by from vimtip #1370, now residing
at http://vim.wikia.com/wiki/Tracking_clipboard_changes

------------------------------------------------------------------------------
Copyright: (C) 2010-2024 Ingo Karkat -
The [VIM LICENSE](http://vimdoc.sourceforge.net/htmldoc/uganda.html#license) applies to this plugin.

Maintainer:     Ingo Karkat &lt;ingo@karkat.de&gt;
