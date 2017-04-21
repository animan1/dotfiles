curl -fLo ~/.vim/autoload/plug.vim --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
ln -s `pwd`/.vimrc ~/.vimrc
vim +PlugInstall
ln -s `pwd`/.gitconfig ~/.gitconfig
ln -s `pwd`/.aliases ~/.aliases
