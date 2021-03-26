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

# Check architecture:
if [ "$(uname -m)" != 'x86_64' ];
then
    echo "Looks like this machine is not x86_64, so will quit"
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

# Set URLs for the dmg based on latest URLS where possible to minimise need
# to update them frequently. App name is based on the final app name used 
# on OSx to help make desktop shortcut making easier.

declare -A AppUrls
## Seeming latest URLS
AppUrls=(
    ["Google Chrome"]="https://dl.google.com/chrome/mac/stable/GGRO/googlechrome.dmg"
    [zoom.us]="https://zoom.us/client/latest/Zoom.pkg"
    #[Firefox]="https://download.mozilla.org/?product=firefox-latest-ssl&os=osx&lang=en-GB"
)
## URLs with version numbers in (Plan is to update this script at some point to grab the latest)
AppUrls+=(
    [Firefox]="https://download-installer.cdn.mozilla.net/pub/firefox/releases/86.0.1/mac/en-GB/Firefox%2086.0.1.dmg"
    [GIMP-2.10]="https://download.gimp.org/mirror/pub/gimp/v2.10/osx/gimp-2.10.22-x86_64-3.dmg"
    [LibreOffice]="https://www.mirrorservice.org/sites/download.documentfoundation.org/tdf/libreoffice/stable/7.1.1/mac/x86_64/LibreOffice_7.1.1_MacOS_x86-64.dmg"
    [Skype]="https://download.skype.com/s4l/download/mac/Skype-8.69.0.88.dmg"
    [VLC]="https://get.videolan.org/vlc/3.0.12/macosx/vlc-3.0.12-intel64.dmg"
    # [Audacity]="https://download.fosshub.com/Protected/expiretime=1613390416;badurl=aHR0cHM6Ly93d3cuZm9zc2h1Yi5jb20vQXVkYWNpdHkuaHRtbA==/a837725e321fd3af31861b5aa144c620bd69816465487640eb6322084cdaa2a3/5b7eee97e8058c20a7bbfcf4/5ef5ead9c63e265869c6d064/audacity-macos-2.4.2.dmg"
)

# Create temp folder for the downloads
TempFolder="LTA-OSx-Script-$(date +%d-%m-%y)"
mkdir "$TempFolder"
cd "$TempFolder"
mkdir mounts

# Loop through URLs and:
# - download to temp
# - mount download
# - install / copy to apps
# - create desktop shortcut (TODO)
# then delete TempFolder and exit
for APP URL in "${(@kv)AppUrls}"
    do
        # Creating subfolders for the app and move in to allow keeping original filenames
        mkdir "$APP"
        cd "$APP"
        
        # Get files
        echo "Going to download $APP ($URL)..."
        curl --progress-bar -L -O "$URL" 
        if [ $? -ne 0 ]
        then 
            echo "Downloading $APP borked"
            exit
        fi
        echo "Finished downloading $APP."
        
        # check if dmg or pkg and handle install appropriately
        if ls ./*.dmg &> /dev/null
        then 
            echo "We have a .dmg to install"
            hdiutil attach -quiet -mountpoint "../mounts/$APP" *.dmg
            echo "$APP should be mounted, will now try and copy to Applications"
            cp -r ../mounts/$APP/*.app /Applications/ 
            if [ $? -ne 0 ]
            then
                echo "Copying $APP borked"
                exit
            fi
            echo "$APP should be installed"
            hdiutil detach -quiet "../mounts/$APP"
        elif ls ./*.pkg &> /dev/null
        then
            echo "We have a .pkg to install."
            sudo installer -pkg *.pkg -target /
        else
            echo "SOMETHINGS GONE WRONG"
            echo "We have found neither .dmg or .pkg to install for $APP"
            echo "This could be due to a new version being out or borked download."
            exit
        fi
        # move back to temp folder to start again
        cd ..
        osascript << EOF
tell application "Finder"
	set ltaapp to POSIX file "/Applications/$APP.app" as alias
	make new alias to ltaapp at desktop
	set name of result to "$APP"
end tell
EOF

        echo "All being well, there should now be a shortcut for $APP on the desktop."        
        # Create Desktop Shortcut / alias
        # TODO, looks like it needs osascript
        # in the meantime will just pop open the app
        # folder at the end of the script

    done

cd ..

echo "Going to delete temp folder ($TempFolder)"
rm -r "$TempFolder"

echo "Going to download the Staying Safe Online PDF to the Desktop"
curl --progress-bar -L https://tomcronin.org/StayingSafeOnline.pdf > ~/Desktop/Staying\ Safe\ Online.pdf

echo "Going to create a shortcut to the feedback form on the Desktop"
osascript << EOF
tell application "Finder"
	make new internet location file at desktop to "https://cutt.ly/lta-recipient-feedback-form"
	set name of result to "Tell us how you're getting on with this computer"
end tell
EOF

# Pop open Audacity URL to speed things up
echo "Finally, will open the Audacity download URL"
open https://www.fosshub.com/Audacity.html
echo "(Just in case a browser window hasn't opened:"
echo "https://www.fosshub.com/Audacity.html )"

exit
