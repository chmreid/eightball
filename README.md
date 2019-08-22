# eightball

**eightball** is a vim plugin to implement custom functionality for black, the
opinionated Python code formatter.

# Installing

## Installing the Black Vim Plugin

It is not necessary to install the Black vim plugin, since eightball is intended
to provide the same functionality, but generalized to provide additional packages
besides Black.

If you already have the Black vim plugin installed, not to worry - the eightball
plugin defines the same functions as Black, with the same names, so there should not
be any conflicts with Black.

## Installing the Eightball Vim Plugin

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
