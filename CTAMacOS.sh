#!/bin/zsh
## Usage: 
##      CTAMacOS.sh
##
## Last updated:
##      2022/02/07
##
## Options:
##      None at the moment
##
## Description:
##      This is a script to download .dmgs for the normal CTA suite of programs
##      and then install them on macOS. 
##
## Caveats:
##      - This is currently only for x86_64 Macs, not the new M1 / ARM based ones.
##      - Requires internet connection
##      - Currently assumes fresh install with none of these apps installed
##
## TODO:
##      - Replace all instances relying on tomcronin.org hosting bits
##      - No clobber
##      - Dry-run flag
##      - Generate offline installer flag
##
## Author:
##      Tom Cronin / tom@tomcronin.org / Contactable in the TechAid Tech WhatsApp group
##
##########################################################

clear
printf "\n   ____                                      _ _         
  / ___|___  _ __ ___  _ __ ___  _   _ _ __ (_) |_ _   _
 | |   / _ \| '_ \` _ \| '_ \` _ \| | | | '_ \| | __| | | |
 | |__| (_) | | | | | | | | | | | |_| | | | | | |_| |_| |
  \____\___/|_| |_| |_|_| |_| |_|\__,_|_| |_|_|\__|\__, |
  _____         _        _    _     _              |___/
 |_   _|__  ___| |__    / \  (_) __| |
   | |/ _ \/ __| '_ \  / _ \ | |/ _\` |
   | |  __/ (__| | | |/ ___ \| | (_| |
   |_|\___|\___|_| |_/_/   \_\_|\__,_|
   \n\n"
                                                                                     
echo "###################################################"
echo "##                                               ##"
echo "##   This script will attempt to download and    ##"
echo "##   install the normal suite of CTA apps:       ##"
echo "##   - Chrome                                    ##"
echo "##   - Firefox                                   ##"
echo "##   - Skype                                     ##"
echo "##   - Zoom                                      ##"
echo "##   - LibreOffice                               ##"
echo "##   - VLC                                       ##"
echo "##   - GIMP                                      ##"
echo "##   - Audacity                                  ##"
echo "##                                               ##"
echo "##   (Audacity has to be downloaded from a       ##"
echo "##   static host as their download hoster only   ##"
echo "##   provide temporary time bounded links)       ##"
echo "##                                               ##"
echo "##   It should be pretty automatic, other than   ##"
echo "##   requesting a password whilst trying to      ##"
echo "##   install Zoom at the start, and requesting   ##"
echo "##   permission to access the Desktop to create  ##"
echo "##   shortcuts.                                  ##"
echo "##                                               ##"
echo "###################################################"
echo ""

TempFolder="CTA-OSx-Script-$(date +%d-%m-%y)"

#################
# Sanity checks #
#################

sanityChecks() {
    # Check architecture:
    if [ "$(uname -m)" != 'x86_64' ];
    then
        echo "Looks like this machine is not x86_64, so will quit."
        echo "M1 / ARM support will happen later. It's just too new."
        exit
    fi

    # Check actually OSx
    if [ "$(uname)" != 'Darwin' ];
    then
        echo "Looks like this machine is not running OSx, so will quit"
        exit
    fi

    # Check macOS version is supported (Mojave / 10.14 or newer)
    majorVersion="$(sw_vers -productVersion | cut -f 1 -d '.' )"
    minorVersion="$(sw_vers -productVersion | cut -f 2 -d '.' )"

    if [ "$majorVersion" -lt 11 ];
    then
        if [ "$minorVersion" -lt 14 ];
        then
            echo "It looks like this machine is running an unsupport macOS version (older than Mojave / 10.14), so will quit"
            echo "Try:"
            echo " - running $ softwareupdate -l to check for updates"
            echo " - or using https://github.com/grahampugh/macadmin-scripts to download and install newer supported versions without the app store"
            echo " - or command + option + R on boot to install latest version from recovery (only if on Sierra 10.12.4 or newer)"
            echo " - or downloading and installing macOS Sierra, then updating with macadmin-scripts"
            echo "   (http://updates-http.cdn-apple.com/2019/cert/061-39476-20191023-48f365f4-0015-4c41-9f44-39d3d2aca067/InstallOS.dmg)"
            exit
        fi
    fi

    # Check if Temp folder exists
}

##################################################
# Handle static stuff like manuals / backgrounds #
##################################################

windowDressing() {
    echo "Going to download the Staying Safe Online PDF to the Desktop"
    curl --progress-bar -L https://5fd7b948-8376-45ee-9740-fcb145158442.usrfiles.com/ugd/5fd7b9_6b09d8c2f611451b864d50a903c0ac4f.pdf > ~/Desktop/Staying\ Safe\ Online.pdf
    echo "Going to download the getting started guide to the Desktop"
    curl --progress-bar -L https://5fd7b948-8376-45ee-9740-fcb145158442.usrfiles.com/ugd/5fd7b9_1b1b265d86b24fbe88161f0648be3e49.pdf > ~/Desktop/Getting\ Started.pdf
    
    echo "Going to create a shortcut to the feedback form on the Desktop"
    osascript << EOF
    tell application "Finder"
    	make new internet location file at desktop to "https://docs.google.com/forms/d/e/1FAIpQLScrnMFfL4q8i4KH2iR6RuI6ez9F77T6Uwn2LlcIUrSFptKriA/viewform"
    	set name of result to "Tell us how you're getting on with this computer"
    end tell
EOF
#     #osascript to set background
#     curl -s https://tomcronin.org/background.png > ~/Downloads/background.png
#     osascript << EOF
#     tell application "System Events"
#         tell every desktop
#             set picture to "~/Downloads/background.png"
#         end tell
#     end tell
# EOF
}

############################
# Download and install app #
############################

installApp() {
    echo "Going to download $2"
    if [[ "$1" == "dmg" ]]
        then
            curl --progress-bar -L -o "$2.dmg" $4
            echo "Installing $2"
            yes | hdiutil mount -nobrowse "$2.dmg" -mountpoint "/Volumes/$2" > /dev/null
            cp -R "/Volumes/$2/$3" /Applications
            echo "Successfully installed $2"
            hdiutil unmount "/Volumes/$2" > /dev/null && rm "$2.dmg"
    elif [[ "$1" = "pkg" ]]
        then
            curl --progress-bar -L -o "$2.pkg" $4
            echo "Installing $2"
            sudo installer -pkg "$2.pkg" -target /
    fi
    osascript << EOF
tell application "Finder"
    set ltaapp to POSIX file "/Applications/$3" as alias
    make new alias to ltaapp at desktop
    set name of result to "$2"
  end tell
EOF
}


##############################
##############################

# Do sanity checks first
sanityChecks

# Create temp folder for the downloads
mkdir ~/$TempFolder
cd ~/$TempFolder

installApp "pkg" "Zoom" "zoom.us.app" "https://zoom.us/client/latest/Zoom.pkg"

installApp "dmg" "Firefox" "Firefox.app" "http://download.mozilla.org/?product=firefox-latest&os=osx&lang=en-US"
installApp "dmg" "Chrome" "Google Chrome.app" "https://dl.google.com/chrome/mac/stable/GGRO/googlechrome.dmg"
installApp "dmg" "Skype" "Skype.app" "http://www.skype.com/go/getskype-macosx.dmg"

installApp "dmg" "VLC" "VLC.app" "http://get.videolan.org/vlc/3.0.16/macosx/vlc-3.0.16-intel64.dmg"
installApp "dmg" "LibreOffice" "LibreOffice.app" "https://download.documentfoundation.org/libreoffice/stable/7.3.0/mac/x86_64/LibreOffice_7.3.0_MacOS_x86-64.dmg"
installApp "dmg" "GIMP" "GIMP-2.10.app" "https://download.gimp.org/mirror/pub/gimp/v2.10/osx/gimp-2.10.30-x86_64.dmg"
installApp "dmg" "Audacity" "Audacity.app" "https://github.com/audacity/audacity/releases/download/Audacity-3.1.3/audacity-macos-3.1.3-Intel.dmg"

windowDressing

echo "Everything should now be installed and sorted."
echo "Please remember to delete this script."
echo "Have a good day."

cd ~
rm -r ~/$TempFolder
exit
