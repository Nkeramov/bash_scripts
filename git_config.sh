#!/bin/bash
#
# This script configure some global options in git like aliases, credential helper,
# user name and email. Tested in Ubuntu and Mac. 
#
# Method of use:
# source git_configure.sh
#

echo ""
echo "Configuring git..."
echo "Write your git username"
read USER
DEFAULT_EMAIL="$USER@users.noreply.github.com"
read -p "Write your git email [Press enter to accept the private email $DEFAULT_EMAIL]: " EMAIL
EMAIL="${EMAIL:-${DEFAULT_EMAIL}}"

echo "Configuring global user name and email..."
git config --global user.name "$USER"
git config --global user.email "$EMAIL"

echo "Configuring global aliases..."
git config --global alias.ci commit
git config --global alias.st status
git config --global alias.br branch
git config --global alias.co checkout
git config --global alias.last 'log -1 HEAD'
git config --global alias.sub "submodule update --remote --merge"
git config --global core.editor "vim"
git config --global credential.helper 'cache --timeout=36000'

read -r -p "Do you want to add ssh credentials for git? [y/n] " RESP
RESP=${RESP,,}    # tolower (only works with /bin/bash)

CHECK_KEY_ED_EXISTS="$HOME/.ssh/id_ed25519.pub"
if [[ $RESP =~ ^(yes|y)$ ]] && ! test -f "$CHECK_KEY_ED_EXISTS"
then
    echo "Configuring git ssh access..."
    ssh-keygen -t ed25519 -C "$EMAIL"
    echo "This is your public key. To activate it in github, got to settings, SHH and GPG keys, New SSH key, and enter the following key:"
    cat ~/.ssh/id_ed25519.pub
    echo -e "\nTo work with the ssh key, you have to clone all your repos with ssh instead of https. For example, for this repo you will have to use the url: git@github.com:miguelgfierro/scripts.git"
elif [[ $RESP =~ ^(yes|y)$ ]] && test -f "$CHECK_KEY_ED_EXISTS"
then
    echo "You have already ssh-key. To activate it in github, got to settings, SHH and GPG keys, New SSH key, and enter the following key:"
    cat ~/.ssh/id_ed25519.pub
fi

echo "git configured"
