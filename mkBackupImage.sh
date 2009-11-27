#/bin/bash
##
#
# Function: Create a sparsebundle diskimage usable for automatic time machine backups. 
# 	    Option: Encrypt the image (has to be decrypted in case a full 
# 	    disjk reinstall is to be performed)
#	    Selected time machine restores can be retrieved from an encrypted image.
#           If the password for an encrypted image is NOT on the system keychain then
#	    the image must be manualy mounted before teim machine can restore from it.
#
# Parameters:
#    -p <path>		(the path where the image will reside. Should be the root of a disk)
#    -s <size>		(the maximum size the image can grow to. Use the -size parameter style from hdiutil)
#    -h <hostname>	(the name of the computer. Defaults to hostname -s)
#    -i HWUUID		(the HW UUID of the host)
#    -e			(to encrypt the image) 
#
# Assumptions:
#    System: Snow Leopard (OS X 10.6.0 or newer)
#    The user is the owner of the directory at <path>
#    It is OK to add a few hidden files in that directory (to enable time machine use)
#    Though run from the terminal, is assumes the user is logged into the console (for keycahin access manipulations)
#
# Issues/bugs:
#    After copying the password from the local login keychain to the 
#    system chain and saving using keychain access, the user keychain becomes 
#    owned by root. 
#    Manual fix: In terminal run 
#    "sudo chown <user name> ~/Library/Keychains/login.keychain" 
#    where <user name> is the short name of the user.
#
# 20090924 SM: Updated to work with Snow Leopard
#              Building on the hints from MacOSXHints.com: 
#              http://www.macosxhints.com/comment.php?mode=view&cid=103622
#              http://www.macosxhints.com/article.php?story=20090905212640957
#
##

usage() {
   echo "Usage: "
   echo "	$0 -p <path> [-s <size>] [-h <hostname>] [-i <host hardware UUID] [-e ]"
   echo "Where"
   echo "      -p <path> is the location of where the image will be located."
   echo "      -s <size> is the optional maximum size (see man hdiutil). Default is the available space on the disk."
   echo "      -h <hostname> is the optional shortname of the host. Default is whatever /bin/hostname -s returns."
   echo "      -i <host hardware UUID> is the HW UUID of the host. Default is whatever /usr/sbin/system_profiler returns."
   echo "      -e if the image is to be encrypted (not reinstallable directly from the install DVD)."
}

#
# Main body
#

# Constants
TIME_MACHINE_2_HOST_PLIST="com.apple.TimeMachine.MachineID.plist"
# Use keychain access to store the password for automatic backups to an encrypted image
KEYCHAIN_ACCESS_APP="/Applications/Utilities/Keychain Access.app"

# set defaults:
HWUUID=`/usr/sbin/system_profiler SPHardwareDataType |/usr/bin/grep 'Hardware UUID:'| /usr/bin/sed s/\ *Hardware\ UUID:\ //g`
# Default encryption method (cfr. man hdiutil)
ENCRYPTION="-encryption AES-128"
# hostname - the current host
BUSOURCE=`/bin/hostname -s`
# Timeout in seconds for the ack from teh user when doing the keychain 
# access operation.
TIMEOUT=120 
# Timeout ack prompt
ACKPROMPT="Hit return when done with the keychain access operation (times out after $TIMEOUT seconds) "


while getopts p:s:h:i:e SWITCH
do
    case $SWITCH in
        p) LOCATION=$OPTARG;;
        s) SIZE_ARG="-size $OPTARG";;
        h) BUSOURCE=$OPTARG;;
	i) HWUUID=$OPTARG;;
	e) ENCRYPT="YES"
	   ENCRYPTION_ARG="${ENCRYPTION}";;
        *) usage; exit;;
    esac
done

if [ "${LOCATION:-NOLOCATION}" = "NOLOCATION" ]
then 
     echo "Error: Missing location for the image"
     usage
     exit 1
fi

# create the image name, based on the computer short name
IMAGENAME="${LOCATION}/${BUSOURCE}.sparsebundle"
DISKNAME='Time Machine Backups'

# create an image
/usr/bin/hdiutil create ${SIZE_ARG} -type SPARSEBUNDLE ${ENCRYPTION_ARG} -volname "${DISKNAME}" -fs HFS+J "${IMAGENAME}"

# Tie it to the backup source (new with Snow Leaopard)
cat << EOF  > "${IMAGENAME}/${TIME_MACHINE_2_HOST_PLIST}"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.backupd.HostUUID</key>
    <string>$HWUUID</string>
</dict>
</plist>
EOF


##
# Capture password if encryption was enabled
#

if [ "${ENCRYPT:-NO}" = "YES" ]
then

# Capture	 the password by opening the image (which requires password entry)
  echo "Remember to check the 'Remember password in my keychain' box when asked for the password"

  /usr/bin/open "${IMAGENAME}"

  echo "remaining step:  "
  echo "Open Keychain Access in the Utilites folder and"
  echo "copy the key for ${BUSOURCE}_${MAC}.sparsebundle from the login chain to the System chain."
  echo "After copying the password to the system chain and receiving a" 
  ech0 "confirmation from you the program will run the command"
  echo ""
  echo "    sudo chown ${USER} ~/Library/Keychains/login.keychain"
  echo ""
  echo "This corrects a permission problem using Keychain Access"
  echo "If you do not confirm then please remember to run the command manually."

  /usr/bin/open "$KEYCHAIN_ACCESS_APP"
  
  if read -t $TIMEOUT -p "$ACKPROMPT" ACKVAR; then
      # Positive ack provided
      echo "Making sure you stay the owner of ~/Library/Keychains/login.keychain"
      sudo chown ${USER} ~/Library/Keychains/login.keychain
  else
      echo ""
      echo "Remember to perform the command"
      echo "sudo chown ${USER} ~/Library/Keychains/login.keychain"
  fi
fi