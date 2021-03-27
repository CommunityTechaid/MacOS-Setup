#!/bin/zsh
# This is a script to download .dmgs for the normal LTA suite of programs
# and then install them on macOS. This is currently only for x86_64 Macs,
# not the new M1 Silicon / ARM based ones.

# Sanity check for ARM
# set URLS
# set list
# mkdir temp
# for app in app list
#     get files
#     mount files
#     copy to applications
#     create shortcut

clear
echo "###################################################"
echo "##                                               ##"
echo "##   This script will attempt to download and    ##"
echo "##   install the normal suite of LTA apps:       ##"
echo "##   - Chrome                                    ##"
echo "##   - Firefox                                   ##"
echo "##   - Skype                                     ##"
echo "##   - Zoom                                      ##"
echo "##   - LibreOffice                               ##"
echo "##   - VLC                                       ##"
echo "##   - GIMP                                      ##"
echo "##                                               ##"
echo "##   (Audacity has to be downloaded manually     ##"
echo "##   at the moment due to their download host)   ##"
echo "##                                               ##"
echo "##   It should be pretty automatic, other than   ##"
echo "##   potentially requesting a password whilst    ##"
echo "##   trying to install a .pkg (e.g. Zoom)        ##"
echo "##                                               ##"
echo "##   Now with added desktop shortcuts            ##"
echo "##                                               ##"
echo "##                                               ##"
echo "###################################################"

TempFolder="LTA-OSx-Script-$(date +%d-%m-%y)"

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

windowPainting() {
    echo "Going to download the Staying Safe Online PDF to the Desktop"
    curl --progress-bar -L https://tomcronin.org/StayingSafeOnline.pdf > ~/Desktop/Staying\ Safe\ Online.pdf
    echo "Going to create a shortcut to the feedback form on the Desktop"
    osascript << EOF
    tell application "Finder"
    	make new internet location file at desktop to "https://cutt.ly/lta-recipient-feedback-form"
    	set name of result to "Tell us how you're getting on with this computer"
    end tell
EOF
    #osascript to set background
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

installApp "dmg" "VLC" "VLC.app" "http://get.videolan.org/vlc/3.0.12/macosx/vlc-3.0.12-intel64.dmg"
installApp "dmg" "LibreOffice" "LibreOffice.app" "https://www.mirrorservice.org/sites/download.documentfoundation.org/tdf/libreoffice/stable/7.1.1/mac/x86_64/LibreOffice_7.1.1_MacOS_x86-64.dmg"
installApp "dmg" "GIMP" "GIMP-2.10.app" "https://download.gimp.org/mirror/pub/gimp/v2.10/osx/gimp-2.10.22-x86_64-3.dmg"

# Currently points to a hosted version as Audacity's current hosting provider doesn't provide any static links, all time limited
installApp "dmg" "Audacity" "Audacity.app" "https://tomcronin.org/Audacity.dmg"

windowPainting

echo "Everything should now be installed and sorted."
echo "Please remember to delete this script."
echo "Have a good day."

cd ~
rm -r ~/$TempFolder
exit
