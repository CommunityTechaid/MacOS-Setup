# CTAMacOS 

This is a script to install the standard suite of Community TechAid programmes on to a Mac.

Core precepts:
- have no prerequisites other than a machine running macOS and an internet connection
- install the latest versions of the programmes
- no / minimal user interaction

Follow up task would be to create a offline version.

## Prerequisites

None. The script deliberately uses default / builtin tools. 

## Usage

On the Mac that will be recieving the programmes:

```zsh
# download the script from github to a local file
curl https://raw.githubusercontent.com/techaid-tech/techaid-macOS/main/CTAMacOS.sh > ./CTAMacOS.sh

# set the script as an executable
chmod +x ./CTAMacOS.sh

# run the script
./CTAMacOS.sh
```
