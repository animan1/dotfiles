# vim
sudo add-apt-repository -y ppa:pi-rho/dev
sudo apt-get update
sudo apt-get install -y vim-gtk
sudo pip install yapf
curl -fLo ~/.vim/autoload/plug.vim --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
ln -s `pwd`/.vimrc ~/.vimrc
vim +PlugInstall

# git
ln -s `pwd`/.gitconfig ~/.gitconfig

# SSH
ln -s `pwd`/.ssh/* ~/.ssh/

# TMUX
ln -s `pwd`/.tmux.conf ~/.tmux.conf

# shell
chsh /bin/zsh
ln -s `pwd`/.aliases ~/.aliases
sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"
rm ~/.zshrc
ln -s `pwd`/.zshrc ~/.zshrc
