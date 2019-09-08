" eightball.vim
"
" This is a vim plugin that provides
" functionality for code formatting
" using Black and friends.
" 
" Keyboard shortcuts defined here
" are as follows:
" (b prefix for Black)
"
" <Leader>be : (vis. mode) echo the contents of the current visual selection
" <Leader>bg : apply Black to entire buffer, preserving cursor location
" <Leader>bG : apply Black to entire buffer, top to bottom
" <Leader>bb : (vis. mode) apply Black to visual selection using black-macchiato
" <Leader>bv : (same as above)
"
" <Leader>bi : initialize eightball virtual environment and install packages
" <Leader>bu : upgrade packages in the eightball virtual environment

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
  "let g:eightball_linelength = 88
  let g:eightball_linelength = 100
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

def _get_pyver():
    return sys.version_info[:2]

def _initialize_virtualenv():
    """
    Description:
        Install and set up a virtual environment for eightball.
    """
    pyver = _get_pyver()
    if pyver < (3, 6):
        print(f"Sorry, {package_name} requires Python 3.6+ to run.")
        return False

    from pathlib import Path
    import subprocess
    import venv
    virtualenv_path = Path(vim.eval(f"g:virtualenv_path")).expanduser()
    virtualenv_site_packages = str(_get_virtualenv_site_packages(virtualenv_path, pyver))
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
    if sys.path[0] != virtualenv_site_packages:
        sys.path.insert(0, virtualenv_site_packages)
    return True

def _install_package(package_name, import_name=None, upgrade=False):
    """
    Description:
        Install and upgrade packages using the eightball virtual environment.

    Arguments:
        package_name: the name of the package to use when installing via pip
        import_name: the name of the package to use when importing into Python
                     (if None, same as package_name)
        upgrade: boolean, upgrade the package with pip if true
    """
    pyver = _get_pyver()
    if not _initialize_virtualenv():
        print('Could not install {package_name} due to problem with virtual environment')
        return False

    if import_name is None:
        import_name = package_name

    from pathlib import Path
    import importlib
    import subprocess

    # Virtual environment paths
    virtualenv_path = Path(vim.eval(f"g:virtualenv_path")).expanduser()
    virtualenv_site_packages = str(_get_virtualenv_site_packages(virtualenv_path, pyver))
    vpip = str(_get_pip(virtualenv_path))

    # Check if a package is available
    try:
        # Try to import the package; if it succeeds, package is installed
        importlib.import_module(import_name)
        if upgrade:
            # Package is already installed,
            # but user specified upgrade option
            print(f'Upgrading {package_name} with pip...')
            vpip = str(_get_pip(virtualenv_path))
            proc = subprocess.run(
                [vpip, 'install', '-U', package_name],
                stdout=subprocess.PIPE
            )
            print(f'Finished upgrading {package_name}')
        else:
            # Package is already installed, nothing to do
            pass
    except ModuleNotFoundError:
        # The package is not present, so install it
        print(f'Installing {package_name} with pip...')
        proc = subprocess.run(
            [vpip, 'install', package_name],
            stdout=subprocess.PIPE
        )
        print(f'Finished installing {package_name}')

    return True


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


##############################
# Black functions
#
# The following functions are refactored
# from functions in black.vim.

def Black():
    """
    Apply black to entire vim buffer, and
    make a half-assed attempt to restore
    the cursor to its original location.
    """
    start = time.time()
    fast = bool(int(vim.eval("g:black_fast")))
    mode = black.FileMode(
        line_length=int(vim.eval("g:eightball_linelength")),
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
        line_length=int(vim.eval("g:eightball_linelength")),
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


##############################
# Black-Macchiato functions
#
# The following functions are refactored
# from functions in black.vim.
# They apply to black-macchiato,
# which formats Python code using
# Black but only 

def VisualBlack():
    # The _get_lineselection method assumes we are
    # in visual mode (so marks < and > are defined),
    # so we must map this to a keybinding in vim
    # in visual mode.
    start = time.time()

    import subprocess

    line_length = int(vim.eval("g:eightball_linelength")),
    current_cursor = vim.current.window.cursor
    lstart, lend, lines = _get_lineselection()
    lines_str = "\n".join(lines)
    p = subprocess.run(
        ["black-macchiato", "--line-length=%d"%(line_length)],
        stdout=subprocess.PIPE,
        input=lines_str,
        text=True
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


##############################
# Eightball functions
# 
# The following functions are for 
# upgrading and installing software
# in eightball's virtual environment.

def EightballInit():
    # This will automatically install a virtual environment
    if _initialize_virtualenv():
        import time

    if _install_package('black'):
        import black
        import time

    if _install_package('black-macchiato', 'macchiato'):
        import macchiato
        import time

def EightballUpgrade():
    _install_package('pip', upgrade=True)
    _install_package('black', upgrade=True)
    _install_package('black-macchiato', upgrade=True)

# Always initialize eightball
if EightballInit():
    pass

endpython3

" Initialize/install command
command! EightballInit :py3 EightballInit()
noremap <Leader>bi :EightballInit<cr>

" Upgrade command
command! EightballUpgrade :py3 EightballUpgrade()
noremap <Leader>bu :EightballUpgrade<cr>

" Print out the visually selected text (demo function)
" (e is for echo)
vnoremap <Leader>be y:py3 PrintMySelection()<CR>

" Apply Black to the entire file,
" remembering line number of cursor.
" (g is for start location (top of document))
command! Black :py3 Black()
noremap <Leader>bG :Black<cr>

" Apply Black to the entire file,
" remembering code location of cursor.
command! BlackCursor :py3 BlackCursor()
noremap <Leader>bg :BlackCursor<cr>

" Apply Black to visual selection.
vnoremap <Leader>bb y:py3 VisualBlack()<cr>
vnoremap <Leader>bv y:py3 VisualBlack()<cr>

python3 << endpython3

