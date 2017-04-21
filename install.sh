curl -fLo ~/.vim/autoload/plug.vim --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
ln -s `pwd`/.vimrc ~/.vimrc
vim +PlugInstall
ln -s ~/projects/dotfiles/.gitconfig ~/.gitconfig
