#!/bin/bash -i

[ -n "$BASH_VERSION" ] || { echo "please run this script with bash"; exit 1; }

echo_with_red_color() {
  echo -e '\e[1;31m'$1'\e[m';
}

echo_with_cyan_color() {
  echo -e '\e[1;36m'$1'\e[m';
}

echo_with_cyan_color "❯❯❯  Configuring git..."
echo "Configuring global user name and email..."
echo "Write your git username"
read USER
git config --global user.name "$USER"

DEFAULT_EMAIL="$USER@users.noreply.github.com"
read -p "Write your git email [Press enter to accept the private email $DEFAULT_EMAIL]: " EMAIL
EMAIL="${EMAIL:-${DEFAULT_EMAIL}}"
git config --global user.email "$EMAIL"

git config --global core.editor "nano"
git config --global init.defaultBranch master


echo_with_cyan_color "❯❯❯  Configuring global aliases..."
git config --global alias.ci commit
git config --global alias.st status
git config --global alias.br branch
git config --global alias.co checkout
git config --global alias.last 'log -1 HEAD'
git config --global alias.sub "submodule update --remote --merge"
git config --global credential.helper 'cache --timeout=36000'

read -r -p "Do you want to add ssh credentials for git? [y/n] " RESP
RESP=${RESP,,}    # tolower (only works with /bin/bash)

CHECK_KEY_ED_EXISTS="$HOME/.ssh/id_rsa.pub"
if [[ $RESP =~ ^(yes|y)$ ]] && ! test -f "$CHECK_KEY_ED_EXISTS"
then
    echo_with_cyan_color "❯❯❯  Configuring git ssh access..."
    ssh-keygen -t rsa -C "$EMAIL"
    echo "This is your public key. To activate it in github, got to settings, SHH and GPG keys, New SSH key, and enter the following key:"
    cat ~/.ssh/id_rsa.pub
    echo -e "\nTo work with the ssh key, you have to clone all your repos with ssh instead of https. For example, for this repo you will have to use the url: git@github.com:miguelgfierro/scripts.git"
elif [[ $RESP =~ ^(yes|y)$ ]] && test -f "$CHECK_KEY_ED_EXISTS"
then
    echo "You have already ssh-key. To activate it in github, got to settings, SHH and GPG keys, New SSH key, and enter the following key:"
    cat ~/.ssh/id_rsa.pub
fi

echo_with_cyan_color "❯❯❯  Git configured"
