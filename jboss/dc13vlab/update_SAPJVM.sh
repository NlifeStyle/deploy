#!/bin/bash

#set -x 

#############################################################
# Update_SAPJVN 
#
# ./Update_SAPJVN <Version#> <optional: force>
#
# <Version#> = SAP JVM Version e.g. 6.1.074    or    7.1.028
# <force> = (optional paramert) 'force' = force installation, anyway if the agent is already installed or not.
# Installation only starts if installed version is different to given in parameter version , or force is set
#
# rpm File of SAP JVM have to be stored on repo  (http://repo:50000/repo/SuccessFactors/Operation/global/landscape/jdk7_libs/)
#                                          resp. (http://repo:50000/repo/SuccessFactors/Operation/global/landscape/jdk6_libs/)
# policies file have to be stored on repo  
#
# 1.  stop the Jboss
# 2.  delete all old JVMs & Links
# 3.  install rpm package 
# 4.  create JVM link
# 5.  copy policies files
#
##############################################################

if [ "$1" == "" ]; then
  echo "Parameter missing!"
  echo "e.g.  ./Update_SAPJVM.sh 7.1.028 <optional: force>"
  exit 1
fi

JVMVERSIONNUM=$1
JVMVERSION="sapjvm_${JVMVERSIONNUM}"

INSTVER=`su - sfuser -c 'java -fullversion' 2>&1 | grep 'java full version'`
INSTVER=${INSTVER#*java full version \"}
INSTVER="${INSTVER%\"}"

#exctract java main version of to install version
VER=${JVMVERSION%%.*}
VER=${VER#*_}

if [ "$2" == "force" ]; then
  FORCE="yes"
else
  FORCE="no"
fi

REPO_HOST="repo:50000"
REPO_ROOT="http://$REPO_HOST/repo"
REPO_BUILD=$REPO_ROOT/SuccessFactors/Operation/build
REPO_APPENDIX="SuccessFactors/Operation/config/QA/DC13/BizX"
REPO_LANDSCAPE=$REPO_ROOT/SuccessFactors/Operation/config/global/landscape
REPO_SCRIPTS=$REPO_ROOT/SuccessFactors/Operation/config/QA/DC13/global

#################################################
# Main 

#create installation log file
VAR_LOGDIR="/export"
VAR_LOGFILE="${VAR_LOGDIR}/sapjvm_update.log"
rm -f $VAR_LOGFILE
echo "Update of SAP JVM ..... ["`date +%F` - `date +%R`"]" > $VAR_LOGFILE
echo >> $VAR_LOGFILE
echo "-----------------------------------------------------------" >> $VAR_LOGFILE
echo "To update to JVM Version         (JVMVERSIONNUM): ${JVMVERSIONNUM}" >> $VAR_LOGFILE
echo "To update to JVM Version [main]  (VER)          : ${VER}" >> $VAR_LOGFILE
echo "FORCE the update                 (FORCE)        : ${FORCE}" >> $VAR_LOGFILE
echo "User sfuser use the Java version (INSTVER)      : ${INSTVER}" >> $VAR_LOGFILE
echo "Script is started with user                     : `whoami`" >> $VAR_LOGFILE
echo "-----------------------------------------------------------" >> $VAR_LOGFILE
echo >> $VAR_LOGFILE
######

cd /export/home


if [ "${JVMVERSIONNUM}" != "${INSTVER}" ] || [ "${FORCE}" == "yes" ]; then
    #echo "JVMVERSIONNUM: ${JVMVERSIONNUM}" >> $VAR_LOGFILE
    #echo "JVMVERSION: ${JVMVERSION}" >> $VAR_LOGFILE
    #echo "INSTVER   : ${INSTVER}" >> $VAR_LOGFILE
    #echo "FORCE     : ${FORCE}" >> $VAR_LOGFILE

  #### 1. stop Jboss
  [ -f /etc/init.d/jboss ] && /etc/init.d/jboss stop
  echo "Stop Jboss server" >> $VAR_LOGFILE


  #### 2. delete all old JVMs & Links
  [ -f /export/home/jdk1.6.0_39.tar.gz ] && rm -r /export/home/jdk1.6.0_39.tar.gz
  [ -h /export/home/jdk6 ] && rm /export/home/jdk6
  [ -d /export/home/jdk1.6.0_39 ] && rm -rf /export/home/jdk1.6.0_39

  [ -f /export/home/sapjvm6.tar.gz ] && rm -r /export/home/sapjvm6.tar.gz
  [ -h /export/home/sapjvm6 ] && rm /export/home/sapjvm6
  [ -d /export/home/sapjvm_6 ] && rm -rf /export/home/sapjvm_6

  [ -f /export/home/sapjvm7.tar.gz ] && rm -r /export/home/sapjvm7.tar.gz
  [ -h /export/home/sapjvm7 ] && rm /export/home/sapjvm7
  [ -d /export/home/sapjvm_7 ] && rm -rf /export/home/sapjvm_7

  echo "delete already existing files" >> $VAR_LOGFILE


  #### 3. install rpm package 
  zypper -n in "${REPO_LANDSCAPE}/${JVMVERSION}-linux-x64.rpm"
  echo "Update the SAP JVM" >> $VAR_LOGFILE

  
  #### 4. create JVM link
  ln -s /usr/java/${JVMVERSION}/ /export/home/sapjvm${VER}


  #### 5. copy policies files
  echo "Copy policies files from SVN" >> $VAR_LOGFILE
  cd /export/home/sapjvm${VER}/jre/lib/security
  rm US_export_policy.jar local_policy.jar cacerts 
  curl -S -s -O http://repo:50000/repo/SuccessFactors/Operation/global/landscape/jdk${VER}_libs/cacerts
  curl -S -s -O http://repo:50000/repo/SuccessFactors/Operation/global/landscape/jdk${VER}_libs/local_policy.jar
  curl -S -s -O http://repo:50000/repo/SuccessFactors/Operation/global/landscape/jdk${VER}_libs/US_export_policy.jar
  sleep 5
  chown -R sfuser:jboss /export/home/sapjvm${VER}/jre/lib/security
  chmod -R 755 /export/home/sapjvm${VER}/jre/lib/security


  # Start the Jboss
  # not needed, because will start by configuration or deployment

else 
  echo "The installed JVM version is same as version in parameter." >> $VAR_LOGFILE
  echo "Nothing to do!" >> $VAR_LOGFILE
fi


echo >> $VAR_LOGFILE
echo "End of SAP JVM upgrade..... ["`date +%F` - `date +%R`"]" >> $VAR_LOGFILE

