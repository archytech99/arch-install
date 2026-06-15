#
# ~/.bash_profile
#

[[ -f ~/.bashrc ]] && . ~/.bashrc

# set PATH so it includes user's private bin if it exists
if [ -d "$HOME/bin" ] ; then
    PATH="$HOME/bin:$PATH"
fi

# User specific environment and startup programs

###### random motd
uptime
echo "         _     ___ _       "
echo " ___ ___|_|___|  _| |_ ___ "
echo "| .'|  _| | -_|  _| . | . |"
echo "|__,|_| |_|___|_| |___|  _|"
echo "                      |_|  "
