# eightball

**eightball** is a vim plugin to implement custom functionality for black, the
opinionated Python code formatter.

# Overview

eightball provides the user with vim functions and
corresponding keyboard shortcuts to do useful things:

* Format an entire Python file using Black, preserving
  the cursor location at the same line of code

* Format only visually selected lines of Python code
  using black-macchiato, a tool to format sections of 
  Python code

* Whitespace-trimming and other tools to help conform
  to PEP8

* Utility functions that illustrate how to use the vim package
  in Python to write plugins

## Keyboard Shortcuts Defined

eightball defines several useful keyboard shortcuts
in vim. 

Note that in the list of keyboard shortcuts, `<Leader>`
refers to the vim leader key, which is `\` by default.
The `,` key is much easier to reach. This Leader key
can be remapped by putting the following in your `~/.vimrc`:

```
" Remap <Leader> from default (\) to something easier (,)
let mapleader = ','
```

List of keyboard shortcuts:

```
<Leader>ee : echo the contents of the current visual selection
<Leader>bg : apply Black to entire buffer, top to bottom
<Leader>bb : apply Black to entire buffer, preserving cursor location
<Leader>bu : upgrade Black
<Leader>bv : print Black version
<Leader>mm : apply black-macchiato to visually selected lines
<Leader>mu : upgrade black-macchiato
```

## Libraries Used

This uses the following libraries:

* Black
* black-macchiato

# Installing eightball

## A Note on the Black Vim Plugin

It is not necessary to install the Black vim plugin, since eightball is intended
to provide the same functionality, but generalized to provide additional packages
besides Black.

If you already have the Black vim plugin installed, not to worry - the eightball
plugin defines the same functions as Black, with the same names, so there should not
be any conflicts with Black.

## Installing the eightball Vim Plugin

Copy the eight-ball plugin at `plugin/eightball.vim` to
`~/.vim/plugin/eightball.vim` to install the eight-ball
vim plugin.

```
mkdir -p \
    ~/.vim/plugin \
    && curl -LSso \
    ~/.vim/plugin/eightball.vim \
    https://raw.githubusercontent.com/chmreid/eightball/master/plugin/eightball.vim
```

You should also open vim, as it will create a Python virtual
environment and install software the first time it opens after
this plugin is installed.

