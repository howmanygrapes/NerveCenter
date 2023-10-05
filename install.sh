#!/bin/bash

dependencies="lolcat figlet pv tar neofetch polybar networkmanager"




function install_deps {
	sudo pacman -Syu && sudo pacman -S $dependencies
	echo "Dependencies installed."
}

function move_stuff {
	cp -r $HOME/NerveCenter/polybar $HOME/.config
}


clear
echo "Starting..."
move_stuff
echo "Done moving stuff, now we're gonna install some stuff."
sleep 1
install_deps
echo "All done. now run ./Nervecenter.sh"
sleep 2
exit 0
