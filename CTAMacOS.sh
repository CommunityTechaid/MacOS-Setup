#!/bin/zsh
## Usage: 
##      CTAMacOS.sh
##
## Last updated:
##      2025/03/12
##
## Options:
##      None at the moment
##
## Description:
##      This is a script to download .dmgs for the normal CTA suite of programs
##      and then install them on macOS. 
##
## Caveats:
##      - Requires internet connection
##      - Currently assumes fresh install with none of these apps installed
##
## TODO:
##      - Pull PDFs from CTA URL pointing at latest
##      - No clobber
##      - Dry-run flag
##      - Generate offline installer flag
##
## Author:
##      Tom Cronin / tom.cronin@communitytechaid.org.uk / Contactable in the TechAid Volunteer WhatsApp group
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
echo "##   - Zoom                                      ##"
echo "##   - LibreOffice                               ##"
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
    if [ "$(uname -m)" != 'x86_64' ] && [ "$(uname -m)" != 'arm64' ];
    then
        echo "Looks like this machine is not a recognised architecture (x86_64 or arm64), so will quit."
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
    curl --progress-bar -L https://5fd7b948-8376-45ee-9740-fcb145158442.usrfiles.com/ugd/5fd7b9_f8f57e7d7dfe46e5a79620645ec42bd0.pdf > ~/Desktop/Staying\ Safe\ Online.pdf
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

if [ "$(uname -m)" != 'x86_64' ];
then
    echo "Installing arm64 / Apple Silicon stuff"

    installApp "pkg" "Zoom" "https://cdn.zoom.us/prod/6.6.6.67409/arm64/zoomusInstallerFull.pkg"

    installApp "dmg" "LibreOffice" "LibreOffice.app" "https://download.documentfoundation.org/libreoffice/stable/25.8.2/mac/aarch64/LibreOffice_25.8.2_MacOS_aarch64.dmg"

else
    echo "Installing x86_64 stuff"
    
    installApp "pkg" "Zoom" "zoom.us.app" "https://cdn.zoom.us/prod/6.6.6.67409/zoomusInstallerFull.pkg"

    installApp "dmg" "LibreOffice" "LibreOffice.app" "https://download.documentfoundation.org/libreoffice/stable/25.8.2/mac/x86_64/LibreOffice_25.8.2_MacOS_x86-64.dmg"
fi

echo "Installing universal stuff"

installApp "dmg" "Chrome" "Google Chrome.app" "https://dl.google.com/chrome/mac/universal/stable/GGRO/googlechrome.dmg"
installApp "dmg" "Firefox" "Firefox.app" "https://download.mozilla.org/?product=firefox-latest-ssl&os=osx&lang=en-GB"

windowDressing

echo "Everything should now be installed and sorted."
echo "Please remember to delete this script."
echo "Have a good day."

cd ~
rm -r ~/$TempFolder
exit
