#!/bin/bash

GREEN='\033[0;32m'
GREENFRAME='\033[0;32;51m'
RED='\033[0;31m'
PURP='\033[0;35m'
REDBLINK='\033[31;5m'
CYAN='\033[0;92m'
BLUE='\033[0;34m'
NC='\033[0m'
figlet_font=$HOME/NerveCenter/figlet_fonts/wideterm.flf
figlet_font_big=$HOME/NerveCenter/figlet_fonts/Doom.flf
figlet_font_small=$HOME/NerveCenter/figlet_fonts/Small.flf
dependencies="lolcat figlet pv netcat" 

              
function display_menu {
    #figlet -f $figlet_font_big "BrainCenter" | lolcat   
    welcome=`ls $HOME/NerveCenter/welcome_art | shuf -n 5`  
    cat $HOME/NerveCenter/welcome_art/$welcome 2>/dev/null | lolcat
    echo # 
    echo -e "${BLUE}      1. Polybar Themes           6. Enable / Disable Firewall${NC}" 
    echo -e "${BLUE}      2. Connect to WiFi          7. Enable / Disable Torctl${NC}"
    echo -e "${BLUE}      3. Update System            8. Install Software${NC}"      
    echo -e "${BLUE}      4. Network Testing          9. Port Scanner${NC}"    
    echo -e "${BLUE}      5. Backup                   ${RED}Press e to EXIT & SAVE${NC}"
    echo #
    #echo -e "${CYAN}
    #echo -e "${CYAN}7. Enable / Disable Torctl${NC}"
    #echo -e "${CYAN}8. Install Software${NC}"
    #echo -e "${CYAN}9. Port Scanner${NC}"
    #echo -e "${RED}Press e to EXIT & SAVE${NC}"
}

function connect_wifi {
    network_list=`nmcli dev wifi | head -20`
    clear
    echo "getting list of available wifi networks..." | lolcat -a
    echo -e "${CYAN}$network_list${NC}"
    read -p "enter the SSID of a network to connect: " network_SSID
    clear
    echo "Connecting to $network_SSID..." &&
    nmcli --ask dev wifi connect $network_SSID &&
    echo -e "${GREEN}Connected to $network_SSID${NC}" || 
    echo -e "${RED}Failed to connect to $network_SSID${NC}"
}

function update_system {
    clear
    sudo pacman -Syu
    clear
    echo -e "${GREEN}System Updated${NC}" 
}

function network_testing {
    clear
    figlet -f $figlet_font "Network testing options" | lolcat
    echo -e "${CYAN}1. test connection${NC}"
    echo -e "${CYAN}2. speedtest${NC}"
    echo -e "${CYAN}3. traceroute to a host${NC}"
    echo -e "${PURP}4. return to main menu${NC}"
    read -p "choose option: " network_option

    case $network_option in 
        1)
            clear
            echo "Testing connection..." | lolcat -a
            while true
            do
                if ping -c 3 -W 5 google.com 1>/dev/null 2>&1 
                    then
                echo -e  "${GREEN}Connected!${NC}"
                break
                else
                    echo -e "${REDBLINK}Not Connected!${NC}"
                    sleep 1
                fi
            done
            ;;
        2)
            clear
            echo "Starting Speedtest..." | lolcat -a
            if command -v speedtest &>/dev/null; then
                speedtest
            else
                read -p "speedtest-cli is not installed. Do you want to install it? (y/n): " install_speedtest
                if [ "$install_speedtest" == "y" ]; then
                    sudo pacman -S speedtest-cli
                else
                    echo -e "${RED}No action taken.${NC}"
                fi
            fi
            ;;
        3)
            clear
            echo "Starting Traceroute..." | lolcat -a
            read -p "Enter a host to traceroute: " host_to_trace
            traceroute $host_to_trace
            ;;
        4)
            clear
            return
            ;;
            
        *)
            echo -e "${RED}INVALID RESPONSE.${NC}"
            ;;
    esac
}

function backup {
    day=$(date +%F%H%M)
    temp=/tmp/tmp_backups
    backup=$HOME/RiceBackups
    dirs=(
        Pictures
        Documents
        .config
        Desktop
        Scripts
    )
    # Setup
    clear
    echo "Starting Backup..." | lolcat -a
    if mkdir -p "$backup" "$temp" "$backup/Rice$day"; then
        echo "Setup comlete, starting backup..."
    else
        echo "Setup failed."
        exit 1
    fi

    # Creates Backup
    for dir in "${dirs[@]}"; do
        tar -cf - "$HOME/$dir" \
            | pv -s $(du -sb "$HOME/$dir" | awk '{print $1}') \
            | gzip > "$temp/backup_$dir.$day.tar.gz"
    done
        
    mv $temp/*.tar.gz $backup/Rice$day && echo "Backup complete. Saved to $backup" || echo "Backup failed."
        rm -r $temp

    read -p "Would you like to backup to an external drive? (yes/no ) " yn

    case $yn in 
        yes ) echo Getting list of available drives...;;
        no ) echo exiting...;NEWT_COLORS=(
        title=,blue
        window=,black
        border=,white
    )
            return;;
        * ) echo invalid responce;
            return;;
    esac

    #Search and list storage devices
    drives=( $(df | grep '/dev/sd|/dev/dm' | awk '{print $6}') )

    #Select storage device menu
    select drive in "${drives[@]}" none; do
        [ "$drive" = "none" ] && exit 
        [ -w "$drive" ] && break || echo "Can't write to $drive"
    done
    echo "Saving backup to $drive"  

    cp -r $backup/Rice$day $drive & PID=$! #simulate a long process

    echo "THIS MAY TAKE A MINUTE..."
    printf "["
    # While process is running...
    while kill -0 $PID 2> /dev/null; do 
        printf  "▓"
        sleep 1
    done
    printf "] done!"
    echo #
}

function firewall_settings {
    clear
    echo "Firewall Settings" | figlet -f $figlet_font | lolcat -a
    echo -e "${CYAN}1. Enable Firewall${NC}"
    echo -e "${RED}2. Disable Firewall${NC}"
    echo -e "${PURP}3. Return to Main Menu${NC}"
    read -p "Enter Option (1,2): " firewall_option
    
    case $firewall_option in
    1)
        echo "Starting Firewall..." | lolcat -a
        if command -v firewalld &>/dev/null; then
            read -p "Are you sure you want to enable the firewall (firewalld)? (y/n): " confirm
            if [ "$confirm" == "y" ]; then
                echo -e "${GREENBLINK}Enabling firewall (firewalld)...${NC}"
                sudo systemctl start firewalld
                echo -e "${GREEN}Firewall (firewalld) enabled successfully.${NC}"
            else
                echo -e {RED}"No action taken.${NC}"
            fi
        else
            read -p "Firewalld is not installed. Do you use UFW? (y/n): " ufw_choice
            if [ "$ufw_choice" == "y" ]; then
                read -p "Are you sure you want to enable the UFW firewall? (y/n): " confirm
                if [ "$confirm" == "y" ]; then
                    echo -e "${GREEN}Enabling UFW firewall...${NC}"
                    sudo ufw enable
                    echo -e "${GREEN}UFW firewall enabled successfully.${NC}"
                else
                    echo -e "${RED}No action taken.${NC}"
                fi
            else
                echo -e "${RED}No action taken.${NC}"
            fi
        fi
        sleep 1
        ;;
    2)
        echo "Stopping Firewall..." | lolcat -a
        if command -v firewalld &>/dev/null; then
            read -p "Are you sure you want to disable the firewall (firewalld)? (y/n): " confirm
            if [ "$confirm" == "y" ]; then
                echo -e "${REDBLINK}Disabling firewall (firewalld)...${NC}"
                sudo systemctl stop firewalld
                echo -e "${GREEN}Firewall (firewalld) disabled successfully.${NC}"
            else
                echo -e "${RED}No action taken.${NC}"
            fi
        else
            read -p "Firewalld is not installed. Do you use UFW? (y/n): " ufw_choice
            if [ "$ufw_choice" == "y" ]; then
                read -p "Are you sure you want to disable the UFW firewall? (y/n): " confirm
                if [ "$confirm" == "y" ]; then
                    echo -e "${REDBLINK}Disabling UFW firewall...${NC}"
                    sudo ufw disable
                    echo -e "${GREEN}UFW firewall disabled successfully.${NC}"
                else
                    echo -e "${RED}No action taken.${NC}"
                fi
            else
                echo -e "${RED}No action taken.${NC}"
            fi
        fi
        sleep 1
        ;;
    3)
        clear
        return
        ;;
    *)
        echo -e "${REDBLINK}INVALID RESPONSE${NC}"
        sleep 1
        ;;
    esac
        
}

function torctl_settings {
    clear
    echo "Torctl Settings" | figlet -f $figlet_font | lolcat -a
    echo -e "${CYAN}1. Enable Torctl${NC}"
    echo -e "${RED}2. Disable Torctl${NC}"
    echo -e "${PURP}3. Return to Main Menu${NC}"
    read -p "Enter Option (1,2): " torctl_option
    case $torctl_option in
    1)
        clear
        echo "Starting Torctl..." | lolcat -a
        if sudo bash $HOME/NerveCenter/scripts/torctl/torctl start; then
            clear
            echo -e "${GREENBLINK}torctl enabled!${NC}"
            sleep 1; 
        else
            echo -e "${RED}Something went wront... make sure torctl is installed.${NC}"
            sleep 1
        fi 
        ;;
    2)
        clear
        echo "Stopping Torctl..." | lolcat -a
        if sudo bash $HOME/NerveCenter/scripts/torctl/torctl stop; then
            clear
            echo -e "${REDBLINK}torctl disabled${NC}"
            sleep 1;
        else
            echo -e "${RED}Something went wront... make sure torctl is installed.${NC}"
            sleep 1
        fi
        ;;
    3)
        clear 
        return
        ;;
    *)
        echo -e "${REDBLINK}INVALID RESPONSE${NC}"
        sleep 1
        ;;
    esac
}

function install_software {
    clear
    echo "Install Software" | figlet -f $figlet_font | lolcat
    echo "Categories" | figlet -f $figlet_font | lolcat 
    echo -e "${CYAN}1. Web Browser${NC}"
    echo -e "${CYAN}2. Multi Media${NC}"
    echo -e "${CYAN}3. Security${NC}"
    echo -e "${PURP}4. Return to Main Menu${NC}"
    read -p "Choose Option: " software_choice
    
    case $software_choice in
        1)
            clear
            echo -e "${GREEN}Select web browser to install${NC}"
            echo -e "${CYAN}1. Firefox${NC}"
            echo -e "${CYAN}2. Brave${NC}"
            echo -e "${CYAN}3. IceWeasle${NC}"
            echo -e "${CYAN}4. tor browser${NC}"
            echo -e "${PURP}5. Return to Main Menu${NC}"
            read -p "Choose Browser: " browser_choice

                case $browser_choice in
                    1)
                        clear
                        echo "installing Firefox..." | lolcat -a
                        sudo pacman -Sy firefox -y
                        clear
                        echo "Done." | lolcat -a
                        clear
                        ;;
                    2)
                        clear
                        echo "installing Brave..." | lolcat -a
                        sudo pacman -Sy brave-bin -y
                        clear
                        echo "Done." | lolcat -a
                        clear
                        ;;
                    3)
                        clear
                        echo "installing IceWeasle..." | lolcat -a
                        sudo pacman -Sy librewolf-bin -y
                        clear
                        echo "Done." | lolcat -a
                        clear
                        ;;
                    4)
                        clear
                        echo "installing Tor Browser..." | lolcat -a
                        sudo pacman -Sy tor-browser -y
                        clear
                        echo "Done." | lolcat -a
                        clear
                        ;;
                    5)
                        clear
                        return
                        ;;
                    *)
                        clear
                        echo -e "${REDBLINK}INVALID RESPONSE${NC}"
                        sleep 2
                        ;;
                esac
            ;;
        2)
            clear
            echo -e "${GREEN}Multi Media Software${NC}"
            echo -e "${CYAN}1. Kdenlive ${RED}Video Editor${NC}"
            echo -e "${CYAN}2. Reaper ${RED}Digital Audio Workstation${NC}"
            echo -e "${CYAN}3. Gimp ${RED}Image Editor${NC}"
            echo -e "${PURP}4. Return to Main Menu${NC}"
            read -p "Select Software: " mm_choice

                case $mm_choice in
                    1)
                        clear 
                        echo "installing Kdenlive" | lolcat -a
                        sudo pacman -Sy kdenlive
                        clear
                        echo -e "${GREEN}Done.${NC}"
                        sleep 2
                        clear
                        ;;
                    2)
                        clear 
                        echo "installing Reaper" | lolcat -a
                        sudo pacman -Sy reaper
                        clear
                        echo -e "${GREEN}Done.${NC}"
                        sleep 2
                        clear
                        ;;
                    3)
                        clear 
                        echo "installing Gimp" | lolcat -a
                        sudo pacman -Sy gimp
                        clear
                        echo -e "${GREEN}Done.${NC}"
                        sleep 2
                        clear
                        ;;
                    4)
                        clear
                        return
                        ;;
                    *)
                        clear
                        echo -e "${REDBLINK}INVALID RESPONSE${NC}"
                        sleep 2
                        ;;
                esac
            ;;
        3)
            clear
            echo -e "${GREEN}Security and Privacy${NC}"
            echo -e "${CYAN}1. Keepassxc ${RED}Password Manager${NC}"
            echo -e "${CYAN}2. Torctl ${RED}Routes all traffic through Tor${NC}"
            echo -e "${CYAN}3. uTox ${RED}Encrypted Messaging Service${NC}"
            echo -e "${CYAN}4. nmap ${RED}Port Scanner${NC}"
            echo -e "${PURP}5. Return to Main Menu${NC}"
            read -p "Select Software: " security_choice

                case $security_choice in
                    1)
                        clear 
                        echo "installing Keepassxc" | lolcat -a
                        sudo pacman -Sy keepassxc
                        clear
                        echo -e "${GREEN}Done.${NC}"
                        sleep 1
                        clear
                        ;;
                    2)
                        clear 
                        echo "installing Torctl" | lolcat -a
                        sudo yay -S torctl-git  
                        clear
                        echo -e "${GREEN}Done.${NC}"
                        sleep 1
                        clear
                        ;;
                    3)
                        clear 
                        echo "installing uTox" | lolcat -a
                        sudo pacman -Sy utox
                        clear
                        echo -e "${GREEN}Done.${NC}"
                        sleep 1
                        clear
                        ;;
                    4)
                        clear
                        echo "installing nmap" | lolcat -a
                        sudo pacman -Syu && sudo pacman -S nmap
                        clear
                        echo -e "${GREEN}Done.${NC}"
                        sleep 1
                        clear
                        ;;
                    5)
                        clear
                        return
                        ;;
                    *)
                        clear
                        echo -e "${REDBLINK}INVALID RESPONSE${NC}"
                        sleep 2
                        ;;
                esac
            ;;
        4)
            clear
            return
            ;;
        *)
            clear
            echo -e "${REDBLINK}INVALID RESPONSE${NC}"
            sleep 1
            ;;
    esac

}

function port_scanner {
    clear
    echo "Port Scanner" | figlet -f $figlet_font | lolcat
    echo -e "${CYAN}Enter IP to scan${NC}"
    read -p "IP address: " ip_address
    nc -nvz $ip_address 1-65535 > $ip_address.txt 2>&1 & PID=$! #simulate a long process

    echo "THIS MAY TAKE A MINUTE..." | lolcat -a
    printf "["
    # While process is running...
    while kill -0 $PID 2> /dev/null; do 
        printf  "▓" | lolcat -a
        sleep 1
    done
    printf "] done!"
    echo # 
    tac $ip_address.txt
    rm -rf $ip_address.txt
}



while true; do
    clear
    display_menu
    read -p "Choose Option (1-9): " selected_option
    case $selected_option in
            1)
                hack_bg="$HOME/NerveCenter/backgrounds/4kland0001.jpg"
                gray_bg="$HOME/NerveCenter/backgrounds/4kland0004.jpg"
                cuts_bg="$HOME/NerveCenter/backgrounds/4kland0005.jpg"
                arch_bg="$HOME/NerveCenter/backgrounds/arch_wallpapers0006.jpg"
                clear
                echo "Polybar Themes" | figlet -f $figlet_font | lolcat
                echo -e "${CYAN}1. hack${NC}"
                echo -e "${CYAN}2. grayblocks${NC}"
                echo -e "${CYAN}3. cuts${NC}"
                echo -e "${PURP}4. Return to Main Manu${NC}"
                read -p "Select polybar theme: " theme


                    case $theme in
                        1)
                            bash $HOME/.config/polybar/launch.sh --hack
                            clear
                            echo "hack applied" | lolcat -a
                            clear
                            sleep 2
                            clear
                            ;;
                        2) 
                            bash $HOME/.config/polybar/launch.sh --grayblocks
                            clear
                            echo "grayblocks applied" | lolcat -a
                            sleep 2
                            clear
                            ;;
                        3)
                            bash $HOME/.config/polybar/launch.sh --cuts
                            clear
                            echo "cuts applied" | lolcat -a
                            sleep 2
                            clear
                            ;;
                        4)
                            clear
                            echo "Returning to Main Menu" | lolcat -a
                            sleep 1
                            ;;

                        *)
                            echo -e "${REDBLINK}INVALID RESPONSE${NC}"
                            sleep 3
                            clear
                            ;;
                    esac
                ;;
            2)
                connect_wifi
                sleep 1
                read -p "Press Enter..."
                clear
                ;;
            3)
                update_system
                sleep 1
                read -p "Press Enter..."
                clear
                ;;
            4)
                network_testing
                sleep 1
                read -p "Press Enter..."
                clear
                ;;
            5)
                backup
                sleep 1
                read -p "Press Enter..."
                clear
                ;;
            6)
                firewall_settings
                sleep 1
                read -p "Press Enter..."
                clear
                ;;
            7)
                torctl_settings
                sleep 1
                read -p "Press Enter..."
                clear
                ;;
            8)
                install_software
                sleep 1                                     
                clear
                ;;
            9)
                port_scanner
                sleep 1
                read -p "Press Enter..."
                clear
                ;;
            e)
                clear
                echo "Exiting... Goodbye!" | figlet -f $figlet_font_big | lolcat 
                sleep 1
                clear
                exit 0
                ;;
            *)
    esac
done


        