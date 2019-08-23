" eightball.vim
"
" This is a vim plugin that provides
" functionality for code formatting
" using Black and friends.
" 
" Keyboard shortcuts defined here
" are as follows:
" <Leader>ee : (vis. mode) echo the contents of the current visual selection
" <Leader>bg : apply Black to entire buffer, top to bottom
" <Leader>bb : apply Black to entire buffer, preserving cursor location
" <Leader>bu : upgrade Black
" <Leader>bv : print Black version
" <Leader>mm : (vis. mode) apply black-macchiato to visually selected lines
" <Leader>mu : upgrade black-macchiato
" <Leader>pg : apply autopep8 to entire buffer, top to bottom
" <Leader>pp : (vis. mode) apply autopep8 to current visual selection
" <Leader>pu : upgrade autopep8
" <Leader>pv : print autopep8 version

if v:version < 700 || !has('python3')
    echo "This script requires vim7.0+ with Python 3.6 support."
    finish
endif

if exists("g:load_eightball")
   finish
endif

let g:load_eightball = "py1.0"

" eightball provides functionality to
" format Python code, using Python
" code-formatting modules. This requires
" management of its own Python packages.
if !exists("g:virtualenv_path")
  let g:virtualenv_path = "~/.vim/eightball"
endif

" Settings that are used across multiple packages
" are set across eightball, while module-specific
" settings can be prefixed with the module name.
if !exists("g:eightball_linelength")
  let g:eightball_linelength = 88
endif

" eightball is intended to replace and expand
" the Black vim plugin, so you can set the same
" options here as in the Black vim plugin and 
" they will be applied just like they would in 
" that plugin.
" These are not prefixed with eightball because
" only Black uses them.
let g:load_black = "py1.0"
if !exists("g:black_fast")
  let g:black_fast = 0
endif
if !exists("g:black_skip_string_normalization")
  let g:black_skip_string_normalization = 0
endif

python3 << endpython3

import os
import sys
import vim


##############################
# Utility functions
# 
# The following functions are pulled
# directly from black.vim, the vim 
# plugin for black.

first_install = {}

def _get_python_binary(exec_prefix):
    try:
        default = vim.eval("g:pymode_python").strip()
    except vim.error:
        default = ""
    if default and os.path.exists(default):
        return default
    if sys.platform[:3] == "win":
        return exec_prefix / 'python.exe'
    return exec_prefix / 'bin' / 'python3'

def _get_pip(venv_path):
    if sys.platform[:3] == "win":
        return venv_path / 'Scripts' / 'pip.exe'
    return venv_path / 'bin' / 'pip'

def _get_virtualenv_site_packages(venv_path, pyver):
    if sys.platform[:3] == "win":
        return venv_path / 'Lib' / 'site-packages'
    return venv_path / 'lib' / f'python{pyver[0]}.{pyver[1]}' / 'site-packages'

def _initialize_package_env(package_name, upgrade=False):
    pyver = sys.version_info[:2]
    if pyver < (3, 6):
        print(f"Sorry, {package_name} requires Python 3.6+ to run.")
        return False

    from pathlib import Path
    import subprocess
    import venv
    virtualenv_path = Path(vim.eval(f"g:virtualenv_path")).expanduser()
    virtualenv_site_packages = str(_get_virtualenv_site_packages(virtualenv_path, pyver))
    first_install = False
    if not virtualenv_path.is_dir():
        print('Please wait, one time virtualenv setup for eightball.')
        _executable = sys.executable
        try:
            sys.executable = str(_get_python_binary(Path(sys.exec_prefix)))
            print(f'Creating a virtualenv in {virtualenv_path}...')
            print('(this path can be customized in .vimrc by setting g:virtualenv_path)')
            venv.create(virtualenv_path, with_pip=True)
        finally:
            sys.executable = _executable
        first_instal = True
    if first_install:
        print(f'Installing {package_name} with pip...')
    if upgrade:
        print(f'Upgrading {package_name} with pip...')
    if first_install or upgrade:
        pp = str(_get_pip(virtualenv_path))
        proc = subprocess.run(
            [pp, 'install', '-U', package_name],
            stdout=subprocess.PIPE
        )
        print(f'Finished installing {package_name}')
    if sys.path[0] != virtualenv_site_packages:
        sys.path.insert(0, virtualenv_site_packages)
    return True

def _install_latest_pip(upgrade=False):
    _initialize_package_env('pip',upgrade=upgrade)

# This will automatically install a virtual environment
if _install_latest_pip():
    import time


##############################
# Vim selection functions
# 
# The following functions are used
# to deal with vim visual selections.

def _get_vselection_cursors():
    # Return the two cursors marking
    # the start and end of the visual
    # selection. Each cursor is a tuple
    # of (line_no, col_no).

    # If this is a visual selection,
    # the marks < and > will mark the
    # beginning and end of the visual
    # selection.
    buf = vim.current.buffer
    mark_start = buf.mark('<')
    mark_end = buf.mark('>')
    return mark_start, mark_end

def _get_vselection():
    # This function returns the text inside a
    # user's visual selection. Map a Python function
    # (that will call this function) to a visual
    # keybinding using vnoremap:
    #
    #    vnoremap ,t y:py3 EchoMySelection()<CR>

    # Get cursor locations
    (lnum1, col1), (lnum2, col2) = _get_vselection_cursors()

    # Get content of lines
    lines = vim.eval('getline({}, {})'.format(lnum1, lnum2))

    # Trim first and last line to selection
    lines[0] = lines[0][col1:]
    lines[-1] = lines[-1][:col2]

    return (lnum1, col1), (lnum2, col2), lines

def _get_lineselection():
    # This function returns the text in
    # every line touched by the current
    # visual selection. This grabs the
    # entire lines, not just the visually
    # selected text.

    # Get cursor locations
    (lnum1, col1), (lnum2, col2) = _get_vselection_cursors()

    # Get content of lines
    lines = vim.eval('getline({}, {})'.format(lnum1, lnum2))

    return lnum1, lnum2, lines

def PrintMySelection():
    _, _, vselection = _get_vselection()
    print("\n".join(vselection))
endpython3

" <Leader>e is the eightball prefix
" e is for echo
" <Leader> e e   --> echo the visual selection
vnoremap <Leader>ee y:py3 PrintMySelection()<CR>


python3 << endpython3
##############################
# Black functions
#
# The following functions are refactored
# from functions in black.vim.

def _initialize_black_env(upgrade=False):
    _initialize_package_env('black',upgrade=upgrade)

if _initialize_black_env():
    import black
    import time


def Black():
    """
    Apply black to entire vim buffer, and
    make a half-assed attempt to restore
    the cursor to its original location.
    """
    start = time.time()
    fast = bool(int(vim.eval("g:black_fast")))
    mode = black.FileMode(
        line_length=int(vim.eval("g:black_linelength")),
        string_normalization=not bool(int(vim.eval("g:black_skip_string_normalization"))),
        is_pyi=vim.current.buffer.name.endswith('.pyi'),
    )
    buffer_str = '\n'.join(vim.current.buffer) + '\n'
    try:
        new_buffer_str = black.format_file_contents(buffer_str, fast=fast, mode=mode)
    except black.NothingChanged:
        print(f'Already well formatted, good job. (took {time.time() - start:.4f}s)')
    except Exception as exc:
        print(exc)
    else:
        cursor = vim.current.window.cursor
        vim.current.buffer[:] = new_buffer_str.split('\n')[:-1]
        try:
            vim.current.window.cursor = cursor
        except vim.error:
            vim.current.window.cursor = (len(vim.current.buffer), 0)
        print(f'Reformatted in {time.time() - start:.4f}s.')

def BlackCursor():
    """
    Apply black to entire vim buffer, and
    do a better job of returning the cursor
    to the same line of code where it was
    originally.
    """
    start = time.time()
    fast = bool(int(vim.eval("g:black_fast")))
    mode = black.FileMode(
        line_length=int(vim.eval("g:black_linelength")),
        string_normalization=not bool(int(vim.eval("g:black_skip_string_normalization"))),
        is_pyi=vim.current.buffer.name.endswith('.pyi'),
    )
    # cursor[0] = current cursor line number, 1-indexed
    # cursor[1] = current cursor column number, 0-indexed
    (cursor_line, cursor_column) = vim.current.window.cursor

    cb = vim.current.buffer[:]
    cb_bc = cb[0:cursor_line]

    # First, format all of the code before the cursor
    # Detect unclosed block at end of "before" chunk
    last_line = cb_bc[-1]
    if last_line.rstrip().endswith(":"):
            cb_bc[-1] = last_line + " pass"

    # Determine old-to-new cursor location mapping
    buffer_str_before = '\n'.join(cb_bc)+'\n'
    try:
        new_buffer_str_before = black.format_file_contents(buffer_str_before, fast=fast, mode=mode)
        new_cb = new_buffer_str_before.split('\n')[:-1]
        new_cursor_line = len(new_cb)
        new_cursor = (new_cursor_line, cursor_column)
    except black.NothingChanged:
        new_cursor_line = cursor_line
        new_cursor = (new_cursor_line, cursor_column)
    except Exception as exc:
        print(exc)

    # Second, format all of the code
    buffer_str = '\n'.join(cb) + '\n'
    try:
        new_buffer_str = black.format_file_contents(buffer_str, fast=fast, mode=mode)
        new_cb = new_buffer_str.split('\n')[:-1]
    except black.NothingChanged:
        print(f'Already well formatted, good job. (took {time.time() - start:.4f}s)')
    except Exception as exc:
        print(exc)
    else:
        # Third, find our place again
        vim.current.buffer[:] = new_cb
        try:
            vim.current.window.cursor = new_cursor
        except vim.error:
            vim.current.window.cursor = (len(vim.current.buffer), 0)
        print(f'Reformatted in {time.time() - start:.4f}s.')

def BlackUpgrade():
    _initialize_black_env(upgrade=True)

def BlackVersion():
    print(f'Black, version {black.__version__} on Python {sys.version}.')
endpython3

" This allows the user to type :Black and have
" the entire document formatted using Black.
" That is mapped to a keyboard shortcut.
command! Black :py3 Black()
noremap <Leader>bg :Black<cr>

" Apply Black to the entire file,
" remembering code location
command! BlackCursor :py3 BlackCursor()
noremap <Leader>bb :BlackCursor<cr>

" Upgrade and version commands
command! BlackUpgrade :py3 BlackUpgrade()
noremap <Leader>bu :BlackUpgrade<cr>

command! BlackVersion :py3 BlackVersion()
noremap <Leader>bv :BlackVersion<cr>


python3 << endpython3
##############################
# Black-Macchiato functions
#
# The following functions are refactored
# from functions in black.vim.
# They apply to black-macchiato,
# which formats Python code using
# Black but only 

def _initialize_macchiato_env(upgrade=False):
    _initialize_package_env('black-macchiato',upgrade=upgrade)

if _initialize_macchiato_env():
    import macchiato
    import time


def VisualMacch():
    # The _get_lineselection method assumes we are
    # in visual mode (so marks < and > are defined),
    # so we must map this to a keybinding in vim
    # in visual mode.
    start = time.time()

    import subprocess

    current_cursor = vim.current.window.cursor
    lstart, lend, lines = _get_lineselection()
    lines_str = "\n".join(lines)
    p = subprocess.run(
        ["black-macchiato"], stdout=subprocess.PIPE, input=lines_str, text=True
    )
    if p.returncode == 0:
        # Get the new Black-ified code
        blackified_str = p.stdout
        blackified = blackified_str.split("\n")[:-1]
        # The new vim buffer will consist of three sections:
        # - everything before the visual selection
        # - the new, Black-ified visual selection
        # - everything after the visual selection
        vim.current.buffer[:] = (
            vim.current.buffer[: lstart - 1] + blackified + vim.current.buffer[lend:]
        )
        # Set the cursor at the start of the visual selection
        vim.current.window.cursor = (lstart, 0)
        print(f"Reformatted in {time.time() - start:.4f}s.")
    else:
        print(f"Already well formatted, good job. (took {time.time() - start:.4f}s)")

def MacchUpgrade():
    _initialize_macchiato_env(upgrade=True)

####################
## Pull request submitted
## to define __version__
#def MacchVersion():
#    print(f'black-macchiato, version {macchiato.__version__} on Python {sys.version}.')
####################
endpython3

" Visual Macch Command
" <Leader>e is the eightball prefix
" m is for black-macchiato
vnoremap <Leader>mm y:py3 VisualMacch()<cr>

" Upgrade and version commands
command! MacchUpgrade :py3 MacchUpgrade()
noremap <Leader>mu :MacchUpgrade<cr>

"command! MacchVersion :py3 MacchVersion()
"noremap <Leader>mv :MacchVersion<cr>


