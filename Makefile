.PHONY: help setup test

help:
	@printf '%s\n' 'make setup  Link dotfiles and install Vim and Zsh plugins' \
	              'make test   Check setup with an isolated home and offline dependencies'

setup:
	@sh ./install.sh

test:
	@sh ./tests/setup.sh
