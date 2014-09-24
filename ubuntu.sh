#!/bin/bash
#
#Karl Chavarria
#12-07-2011
#This script customizes a basic Ubuntu install with my preferences and removes some packages I don't like
#

#Disables 'Recent Documents' logging
recent_docs() {

echo "" > ~/.local/share/recently-used.xbel
sudo chattr +i ~/.local/share/recently-used.xbel

}

#Enable proper repositories
repositories() {

echo -e "#\ndeb http://us.archive.ubuntu.com/ubuntu/ natty-updates restricted main multiverse universe" >> /etc/apt/sources.list

}

#Remove the crap I don't want
apt_clean() {

apt-get -y remove gwibber empathy evolution

}

#Cleanly remove UbuntuOne
rem_one() {

ps ax | grep -v grep | grep -i ubuntuone | awk '{print $1}' | xargs kill
rm –rf ~/.local/share/ubuntuone
rm –rf ~/.cache/ubuntuone
rm –rf ~/.config/ubuntuone
rm –rf ~/Ubuntu\ One
sudo apt-get -y remove ubuntuone-client* python-ubuntuone-storage*

}

#Remove annoying indicator applets and restart gnome
ind_applets() {

sudo apt-get -y remove indicator-me indicator-messages
killall gnome-panel

}

#Clean out apt cache
clean() {

sudo apt-get purge  
sudo apt-get clean

}

#Run apt upgrades and updates
upgrade() {

sudo apt-get update; sudo apt-get update
sudo apt-get -y upgrade  
sudo apt-get update; sudo apt-get update

}

#Install stuff I want
sudo apt-get -y install mplayer gimp pidgin gcc nmap gkrellm elinks links2 screen tsocks tsclient

#Update .bashrc with custom aliases
bashrc_update() {

echo -e "\n########################################################################" >>~/.bashrc
echo -e "Personal shortcuts/aliases" >>~/.bashrc
echo -e "########################################################################" >>~/.bashrc

echo "alias cdclear='cd; clear'
alias celar='clear'
alias ckear='clear'
alias cklaer='clear'
alias cklear='clear'
alias claer='clear'
alias cleare='clear'
alias clera='clear'
alias cler='clear'
alias dclear='clear'
alias df='df -h'
alias du='du -h'
alias eixt='exit'
alias exiot='exit'
alias exot='exit'
alias ext='exit'
alias exti='exit'
alias fiel='file'
alias free='free -m'
alias grep='grep --color'
alias lear='clear'
alias l='ls -a'
alias ls='ls --color=auto'
alias mdir='mkdir'
alias pign='ping'
alias rls='ls --color=auto'
alias rm='rm -i'
alias sl='ls --color=auto'
alias xit='exit'" >> ~/.bashrc

echo -e "#" >> ~/.bashrc

}

#################################################################################
recent_docs;
repositories;
apt_clean;
rem_one;
ind_applets;
clean;
upgrade;
bashrc_update;

