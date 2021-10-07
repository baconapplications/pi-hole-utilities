#!/bin/bash
# randybacon
# 09.12.21
# helper to archive needed files to transfer pi-hole config to another machine (or back it up)

#### adjust these to your configuration (eg where pi-hole is running from docker)

# just a temp dir writeable by this process
tempDir="/data/temp";
# path to root docker files used by pi-hole (eg /etc-pihole)
piHoleRoot="data/pi-hole";

#### list of arguments expected in the input

# input directory to zip
inputDirs="/$piHoleRoot/etc-dnsmasq.d,/$piHoleRoot/etc-pihole";
# output tar file
outputFile="";
# set by -b flag
isBak=false;

#### start internal vars
optstring=":hi:o:b";
currentdate=`date +"%Y-%m-%d-%H%M%S"`;
isBakTxt="-bak";

#ge incoming args
while getopts ${optstring} flag
do
    case ${flag} in
        h)
            printf "\n\nusage:\n-i inputDirectories - comma delimited.  default is /data/pi-hole/etc-dnsmasq.d,/data/pi-hole/etc-pihole\n-o outputFile default is pi-hole-docker-[DATE].tar.gz\n\n"
            exit 0;
        ;;
        b) isBak=true;;
        :)
            printf "$0: Must supply an argument to -$OPTARG." >&2
            exit 1;
        ;;
        i) inputDirs=${OPTARG};;
        o) outputFile=${OPTARG};;
        ?)
            printf "Invalid option: -${OPTARG}."
            exit 2;
        ;;
    esac
done

#copy input dirs to temp dir so we can avoid changing files
tempInputDirs="";
for i in ${inputDirs//,/ }
do
    tempDataDir="${tempDir}/${i//\/$piHoleRoot\//}";
    echo "copying ${i} to temp dir ${tempDataDir}";
    if [ -d ${tempDataDir} ]
    then
        rm -r ${tempDataDir};
    fi
    mkdir -p ${tempDataDir};
    cp -r ${i}/* ${tempDataDir};
    tempInputDirs="${tempInputDirs},${tempDataDir}";
    #if in etc-dnsmasq.d going to rename dhcp related files _bak so we don't spin them up on the backup machine and cause conflicts
    if [[ $i == *"dnsmasq.d"* ]];
    then
        mv ${tempDataDir}/02-pihole-dhcp.conf ${tempDataDir}/02-pihole-dhcp.conf_bak
        mv ${tempDataDir}/04-pihole-static-dhcp.conf ${tempDataDir}/04-pihole-static-dhcp.conf_bak
    fi
done
tempInputDirs=${tempInputDirs:1};

# if not backup exclude files we don't need
exclude="";
if [ "$isBak" = false ] 
then
    isBakTxt="";
    exclude="--exclude /**/*/setupVars.conf* --exclude /**/*/pihole-FTL.db --exclude *migration_backup ";
fi
#adjust input output if need be
tempInputDirs="${tempInputDirs//,/ }"
printf "inputDirs: $tempInputDirs\n";
outputFile="${outputFile:=pi-hole-docker-$currentdate$isBakTxt.tar.gz}"
printf "outputFile: $outputFile\n";

replaceDir=${tempDir:1};
replaceDir="${replaceDir//\//\\/}";
#remove temp dir from path and replace with pihole
tar $exclude-zcvf $outputFile --transform "s,${replaceDir},pihole," $tempInputDirs
