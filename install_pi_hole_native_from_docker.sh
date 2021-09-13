#!/bin/bash
# randybacon
# 09.12.21
# helper to set up pi-hole in data directory and use copied files

#### adjust these to your configuration (eg where pi-hole is running)
piholeUser="pihole";
dataPiHoleDest="/data/pi-hole";
tmpDir="/data/temp";

#note by default dnsmasq.d is /etc/dnsmasq.d and owned by root
dnsMasqDest="/etc/dnsmasq.d";
etcPiHoleSymLink="/etc/pihole";
tarFilePath="/pihole";
tarMasqDir="etc-dnsmasq.d";
tarEtcPiHoleDir="etc-pihole";
inputTar="";

#do not edit vars
sudoCmd="sudo -E sh -c";
piholeUserCmd="sudo -E -u pi";

#ge incoming args
optstring=":hi:o:b"
while getopts ${optstring} flag
do
    case ${flag} in
        h)
            printf "\n\nusage:\n-i input tar file\n\n"
            exit 0;
        ;;
        i) inputTar=${OPTARG};;
        ?)
            printf "Invalid option: -${OPTARG}."
            exit 2;
        ;;
    esac
done

#functions
function createDir() {
   dirToCreate=$1;
   echo "seeing if we need to create ${dirToCreate} dir";
   if [ ! -d ${dirToCreate} ]
   then
      echo "creating ${dirToCreate} dir";
      $piholeUserCmd mkdir ${dirToCreate}
      $piholeUserCmd chmod 775 ${dirToCreate}
   fi
}

#check tar populated
if [ -z "${inputTar}" ];
then
   echo "-i inputTar is required to process this script";
   exit 1;
fi

#create dirs if need be
createDir ${dataPiHoleDest};
createDir ${tmpDir};

#see if root /etc/pihole is a symlink
if [ -L ${etcPiHoleSymLink} ] ; then
   if [ -e ${etcPiHoleSymLink} ] ; then
      echo "${etcPiHoleSymLink} symlink exists - skipping create"
   else
      echo "${etcPiHoleSymLink} symlink is broken - please fix"
      exit 1;
   fi
elif [ -e ${etcPiHoleSymLink} ] ; then
   echo "${etcPiHoleSymLink} symlink does not exist - creating"
   $sudoCmd "mv ${etcPiHoleSymLink} ${etcPiHoleSymLink}-orig"
   $sudoCmd "ln -s ${dataPiHoleDest} ${etcPiHoleSymLink}"
   $sudoCmd "chown -h :${piholeUser} ${etcPiHoleSymLink}"
   #todo fix this
   #chmod -h 775 ${etcPiHoleSymLink}
else
   echo "${etcPiHoleSymLink} does not exist and is expected to"
   exit 2;
fi

#clean temp dir
$piholeUserCmd rm -r ${tmpDir}/*;

#unzip tar file
$piholeUserCmd tar -xvf ${inputTar} -C ${tmpDir};

#stop services
$sudoCmd systemctl stop pihole-FTL

#copy to right dir(s)
$piholeUserCmd cp -r $tmpDir$tarFilePath/$tarEtcPiHoleDir/*  $dataPiHoleDest

#copy dns masq files
$sudoCmd "cp -r $tmpDir$tarFilePath/$tarMasqDir/*  $dnsMasqDest"

sudo cp -r pihole-orig/* /data/pihole

#clean up temp files
$piholeUserCmd rm -r ${tmpDir}/*;

#start services
$sudoCmd systemctl start pihole-FTL

#status dump
$sudoCmd journalctl --unit=pihole-FTL.service | tail -n 10
