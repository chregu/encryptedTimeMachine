#/bin/bash
##
#
# Function: Decrypt an encrypted time machine backup disk image, 
# 	    make it usable for a time machine reinstall from a snow leopard install DVD
#
# Parameters:
#    -i <source image>		(the image to be decrypted)
#    -o <filename>		(the name of the decrypted image. Should be the root of a disk)
#    -q				(quiet mode. Cfr. man hdiutil)
#
# Assumptions:
#    The user is the owner of the image and the directory where the copy is to be made
#    The source and destination have distinct names.
#    It is OK to add a few hidden files in that directory (to enable time machine use)
#
# Bugs:
#    None known
##

usage() {
   echo "Usage: "
   echo 	"$0 -i <image> -o <image name>"
   echo "Where"
   echo "      -i <image> is the name of the image to be decrypted."
   echo "      -o <image name> is the name of the decrypted image."
   echo "      -q close stdout and stderr (see man hdiutil>."
}

#
# Main body
#

# Constants
TIME_MACHINE_2_HOST_PLIST="com.apple.TimeMachine.MachineID.plist"

# set defaults:
QUIET_ARG="";

while getopts i:o:q SWITCH
do
    case $SWITCH in
        o) DESTINATION=$OPTARG;;
	i) SOURCE=$OPTARG;;
	q) QUIET_ARG="-quiet";;
        *) usage; exit;;
    esac
done

if [ "${SOURCE:-NOLOCATION}" = "NOLOCATION" ]
then 
     echo "Error: Missing input image name"
     usage
     exit 1
fi

if [ "${DESTINATION:-NOLOCATION}" = "NOLOCATION" ]
then 
     echo "Error: Missing output name"
     usage
     exit 1
fi

# decrypt the image
hdiutil convert -format UDSB -o "${DESTINATION}"  "${SOURCE}"

# if the above fails, try with this:
# hdiutil convert "${SOURCE}" -format UDSB -o "${DESTINATION}"


# Copy over the ID of the compuer whose backup is being copied source (new with Snow Leaopard)
cp -p "${SOURCE}/${TIME_MACHINE_2_HOST_PLIST}" "${DESTINATION}"/

