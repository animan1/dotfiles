# vim
curl -fLo ~/.vim/autoload/plug.vim --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
ln -s `pwd`/.vimrc ~/.vimrc
vim +PlugInstall

# git
ln -s `pwd`/.gitconfig ~/.gitconfig

# shell
chsh /bin/zsh
ln -s `pwd`/.aliases ~/.aliases
sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"
rm ~/.zshrc
ln -s `pwd`/.zshrc ~/.zshrc

# SSH
ln -s `pwd`/.ssh/* ~/.ssh/
