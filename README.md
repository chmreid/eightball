# eightball

**eightball** is a vim plugin to implement custom functionality for black, the
opinionated Python code formatter.

# Installing

## Installing the Black Vim Plugin

You should probably have the Black vim plugin installed
before you install the eight ball vim plugin, since the
Black vim plugin provides some basic functionality that
is extended with this plugin.

Clone the [Black repo](https://github.com/psf/black), and copy
the Black plugin at `plugins/black.vim` to `~/.vim/plugins/black.vim`.

Or just run this one-liner:

```
mkdir -p \
    ~/.vim/plugin \
    && curl -LSso \
    ~/.vim/plugin/black.vim \
    https://raw.githubusercontent.com/psf/black/master/plugin/black.vim
```

## Installing the Eight Ball Vim Plugin

Copy the eight-ball plugin at `plugins/eightball.vim` to 
`~/.vim/plugins/eightball.vim` to install the eight-ball
vim plugin.

```
mkdir -p \
    ~/.vim/plugin \
    && curl -LSso \
    ~/.vim/plugin/eightball.vim \
    https://raw.githubusercontent.com/chmreid/eightball/master/plugin/black.vim
```
