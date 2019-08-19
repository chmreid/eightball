# eightball

**eightball** is a vim plugin to implement custom functionality for black, the
opinionated Python code formatter.

# Installing

## Installing the Black Vim Plugin

You should probably install the Black vim plugin
before you install the eight ball vim plugin, since the
Black vim plugin provides some basic functionality that
is extended with this plugin.

Clone the [Black repo](https://github.com/psf/black), and copy
the Black plugin at `plugin/black.vim` to `~/.vim/plugin/black.vim`.

Or just run this one-liner:

```
mkdir -p \
    ~/.vim/plugin \
    && curl -LSso \
    ~/.vim/plugin/black.vim \
    https://raw.githubusercontent.com/psf/black/master/plugin/black.vim
```

## Installing the Eight Ball Vim Plugin

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
