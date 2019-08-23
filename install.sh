#!/bin/bash

mkdir -p \
    ~/.vim/ftplugin/python \
    && curl -LSso \
    ~/.vim/ftplugin/python/eightball.vim \
    https://raw.githubusercontent.com/chmreid/eightball/master/ftplugin/python/eightball.vim
