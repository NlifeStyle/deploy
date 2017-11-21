#!/bin/bash

##################################################################
### SAP BizX configuration script
###
### Calling: ./jboss.setup.sh <landscape> <jboss type> 
### <landscape>  => one of QACAND2, QAPATCH2,.....
### <jboss type> => one of CFAPP,SFAPI,QUARZ,... 
### e.g. 
### <landscape>  = QACAND2
### <jboss type> = CFAPP
### jboss.setup.sh QACAND2 CF
###
###################################################################

case "$1" in 
   QAPATCH2|QACAND2|QAAUTOCAND|QACAND|BIZX2|DC13QAPH|QAAUTOPH|DC13PFHA|DC12PRD1|PERFLOAD|PERFSANITY|QARMDA|MONSOON|QAUPGR|QAVERIHANA);;
   *)   echo "Landscape $1 does not match with permitted."
        echo "e.g.  ./jboss.setup.sh QACAND2 CFAPP"
        exit 1;;
esac

if [ "$2" == "" ]; then
  echo "The 'jboss type' is missing!"
  echo "Calling: ./copy.setup.jboss <landscape = [QACAND or QAAUTOCAND or ...]> <jboss type>"
  echo "<jboss type> = CFAPP, SFAPI, SOAP, QUARTZ, REPORT, SEARCHUPD, SEARCHQRY, JMS, CAREER, BIRT, ATTACH, AGENCY, JMS, IMG,EBS,..."
  echo "e.g.  ./jboss.setup QAPATCH2 CFAPP"
  exit 1
fi

set -x 

#################################################
# Define environment
#################################################
export LANDSCAPE=$1
export JBOSS_TYPE=$2

export CONFIG_ROOT=/export/home/config
export REPO_HOST="repo:50000"
export REPO_ROOT="http://$REPO_HOST/repo"
export REPO_BUILD=$REPO_ROOT/SuccessFactors/Operation/build
  
#different repositories
if [ "$LANDSCAPE" == "DC12PRD1" ]; then
  export REPO_APPENDIX="SuccessFactorsProduction/DC12"
  export REPO_LANDSCAPE=$REPO_ROOT/$REPO_APPENDIX/landscape
  export REPO_SCRIPTS=$REPO_ROOT/$REPO_APPENDIX/scripts
  export REPO_BUILD="http://repo:50000/repo/SuccessFactors/Operation/build"
  export REPO_ROOT_AUTH_WGET="--user=deploy --password=nie8Xohngo"
  export REPO_ROOT_AUTH_CURL="--user deploy:nie8Xohngo"
elif [ "$LANDSCAPE" == "QACAND" ] || [ "$LANDSCAPE" == "QAAUTOCAND" ] || [ "$LANDSCAPE" == "QAPATCH2" ] || [ "$LANDSCAPE" == "BIZX2" ] || [ "$LANDSCAPE" == "DC13QAPH" ] || [ "$LANDSCAPE" == "QAAUTOPH" ] || [ "$LANDSCAPE" == "DC13PFHA" ] || [ "$LANDSCAPE" == "PERFLOAD" ] || [ "$LANDSCAPE" == "PERFSANITY" ] || [ "$LANDSCAPE" == "QAUPGR" ] || [ "$LANDSCAPE" == "QAVERIHANA" ]; then
  export REPO_APPENDIX="SuccessFactors/Operation/config/QA/DC13/BizX"
  export REPO_LANDSCAPE=$REPO_ROOT/SuccessFactors/Operation/config/global/landscape
  export REPO_SCRIPTS=$REPO_ROOT/SuccessFactors/Operation/config/QA/DC13/global
elif [ "$LANDSCAPE" == "QARMDA" ] || [ "$LANDSCAPE" == "MONSOON" ]; then
  export REPO_APPENDIX="SuccessFactors/Operation/config/QA/DEV/BizX"
  export REPO_LANDSCAPE=$REPO_ROOT/SuccessFactors/Operation/config/global/landscape
  export REPO_SCRIPTS=$REPO_ROOT/SuccessFactors/Operation/config/QA/DC13/global
else
  export REPO_ROOT="unknown"
  echo "ERROR - no REPO_ROOT defined for ${LANDSCAPE}!"
  exit 1
fi

#will set in setup_env.sh
export TRUNK="unknown"   

#################################################
# create installation log file
#################################################
VAR_LOGFILE=/export/server_install.log
[ -f $VAR_LOGFILE ] && rm -r $VAR_LOGFILE
echo "Start installation of Jboss server..... ["`date +%F` - `date +%R`"]" > $VAR_LOGFILE
echo >> $VAR_LOGFILE
echo "Landscape : ${LANDSCAPE}" >> $VAR_LOGFILE
echo "Jboss-type: ${JBOSS_TYPE}" >> $VAR_LOGFILE

#################################################
# Check for Script changes
#################################################
cd /export
mv jboss.setup.sh jboss.setup.sh.old
curl -S -s $REPO_ROOT_AUTH_CURL -O $REPO_SCRIPTS/jboss.setup.sh
chmod 755 jboss.setup.sh 
diff jboss.setup.sh.old jboss.setup.sh 
if [ "$?" == 1 ]; then
  echo "File jboss.setup.sh changed, please restart."
  echo "File jboss.setup.sh changed, please restart." >> $VAR_LOGFILE
  rm jboss.setup.sh.old
  exit 1
fi
rm jboss.setup.sh.old

#################################################
# Check if run.conf exists
# or jboss_type is ok
#################################################
if [ "$JBOSS_TYPE" == "JAMES" ] || [ "$JBOSS_TYPE" == "HORNET" ]; then
  echo "A run.conf for jboss_type ${JBOSS_TYPE} is not needed"
  echo "A run.conf for jboss_type ${JBOSS_TYPE} is not needed" >> $VAR_LOGFILE
else 
  wget $REPO_ROOT_AUTH_WGET $REPO_ROOT/$REPO_APPENDIX/$LANDSCAPE/jboss/jboss_type/$JBOSS_TYPE/run.conf
  if [ $? == 1 ]; then
	  echo "No run.conf for jboss_type ${JBOSS_TYPE}"
	  echo "No run.conf for jboss_type ${JBOSS_TYPE}" >> $VAR_LOGFILE
	  exit 1
  fi
  rm run.conf*
fi

#Standard value for Jboss 
export JBOSS=jboss-4.3.0.V.12.tgz

if [ "$JBOSS_TYPE" == "HORNET" ]; then
  echo "The jboss_type ${JBOSS_TYPE} has an special version." 
  echo "The jboss_type ${JBOSS_TYPE} has an special version." >> $VAR_LOGFILE
  export JBOSS=jboss-eap-6.2.tar.gz
fi
if [ "$JBOSS_TYPE" == "JAMES" ]; then
  echo "The jboss_type ${JBOSS_TYPE} has an special version." 
  echo "The jboss_type ${JBOSS_TYPE} has an special version." >> $VAR_LOGFILE
  export JBOSS=james-2.3.2.tar.gz
fi
if [ "$JBOSS_TYPE" == "EMAIL" ]; then
  echo "The jboss_type ${JBOSS_TYPE} has an special version." 
  echo "The jboss_type ${JBOSS_TYPE} has an special version." >> $VAR_LOGFILE
  export JBOSS=jboss-6.0.tar.gz
fi
if [ "$JBOSS_TYPE" == "SELFSRV" ]; then
  echo "Is jboss_type ${JBOSS_TYPE} still used?"
  echo "SELFSRV is not used since 1302"
  echo "Please check the setup with Danny Loo (danny.loo@sap.com)"
  echo "Is jboss_type ${JBOSS_TYPE} still used? SELFSRV is not used since release b1302. Please check the setup with Danny Loo (danny.loo@sap.com)" >> $VAR_LOGFILE
  echo "--- end of script ---" >> $VAR_LOGFILE
  exit 1
fi
if [ "$JBOSS_TYPE" == "SOAP" ]; then
  echo "Is jboss_type ${JBOSS_TYPE} still used?"
  echo "SOAP function availabel in all other systems"
  echo "But if really needed, please check the setup with Danny Loo (danny.loo@sap.com)"
  echo "Is jboss_type ${JBOSS_TYPE} still used? SOAP function availabel in all other systems. But if really needed, please check the setup with Danny Loo (danny.loo@sap.com)" >> $VAR_LOGFILE
  echo "--- end of script ---" >> $VAR_LOGFILE
  exit 1
fi
if [ "$JBOSS_TYPE" == "MEMCACHE" ]; then
  echo "Setup for jboss_type ${JBOSS_TYPE} unclear"
  echo "Please check the setup with Danny Loo (danny.loo@sap.com)"
  echo "Setup for jboss_type ${JBOSS_TYPE} unclear. Please check the setup with Danny Loo (danny.loo@sap.com)" >> $VAR_LOGFILE
  echo "--- end of script ---" >> $VAR_LOGFILE
  exit 1
fi
#used only for solr3
if [ "$JBOSS_TYPE" == "SEARCHQRY" ]; then
  if [ -f /export/home/jboss/jboss-4.3.0/server/sfv4Cluster01/solr/solr.xml ]; then
    echo "Found solr3 configuration, therefore a re-installation of the SEARCHQRY server not allowed." 
    echo "Please remove the old setup/configuration manually and do the reinstallation again"
    echo "Found solr3 configuration, therefore a re-installation of the SEARCHQRY server not allowed." >> $VAR_LOGFILE    
    echo "Please remove the old setup/configuration manually and do the reinstallation again." >> $VAR_LOGFILE
    echo "Please note! If you delete the configuration, you have to configure all companies for solr3 manually again!!" >> $VAR_LOGFILE
    echo "--- end of script ---" >> $VAR_LOGFILE
    exit 1
  fi
fi
#used only for solr3
if [ "$JBOSS_TYPE" == "SEARCHUPD" ]; then
  if [ -f /export/home/jboss/jboss-4.3.0/server/sfv4Cluster01/solr/solr.xml ]; then
    echo "Found solr3 configuration, therefore a re-installation of the SEARCHUPD server not allowed." 
    echo "Please remove the old setup/configuration manually and do the reinstallation again"
    echo "Found solr3 configuration, therefore a re-installation of the SEARCHQRY server not allowed." >> $VAR_LOGFILE    
    echo "Please remove the old setup/configuration manually and do the reinstallation again." >> $VAR_LOGFILE
    echo "Please note! If you delete the configuration, you have to configure all companies for solr3 manually again!!" >> $VAR_LOGFILE
    echo "--- end of script ---" >> $VAR_LOGFILE
    exit 1
  fi
fi
#used only for solr4
if [ "$JBOSS_TYPE" == "SEARCH" ]; then
  if [ -f /export/home/jboss/jboss-4.3.0/server/sfv4Cluster01/solr/solr.xml ]; then
    echo "Found solr4 configuration, therefore a re-installation of the SEARCH server not allowed." 
    echo "Please remove the old setup/configuration manually and do the reinstallation again"
    echo "Found solr4 configuration, therefore a re-installation of the SEARCH server not allowed." >> $VAR_LOGFILE    
    echo "Please remove the old setup/configuration manually and do the reinstallation again." >> $VAR_LOGFILE
    echo "Please note! If you delete the configuration, you have to configure all companies for solr4 via provisioning tool again!!" >> $VAR_LOGFILE
    echo "--- end of script ---" >> $VAR_LOGFILE
    exit 1
  fi
fi

#################################################
# Cleanup old backups
#################################################
rm -r /etc/init.d/jboss.201?-*
rm -r /export/home/jboss.201?-*
rm -r /export/home/sfuser.201?-*
echo "Cleanup of old backups done." >> $VAR_LOGFILE
    
#################################################
# Create sfuser home
#################################################
#[ -d /export/home/sfuser ] && mv /export/home/sfuser /export/home/sfuser.`date +%F`.`date +%R`
[ -d /export/home/sfuser ] && rm -r /export/home/sfuser
cd /export
mkdir -p /export/home/sfuser
chown -R sfuser ./home

cd /export/home/sfuser
[ -f bash_profile ] && rm -f bash_profile
[ -f .bash_profile ] && rm -f .bash_profile
wget $REPO_ROOT_AUTH_WGET $REPO_ROOT/$REPO_APPENDIX/$LANDSCAPE/jboss/bash_profile
mv bash_profile .bash_profile
chown sfuser:jboss .bash_profile
echo "Create sfuser home done." >> $VAR_LOGFILE

#################################################
# Load sfuser environment (JAVA_HOME)
#################################################
. /export/home/sfuser/.bash_profile
echo "JAVA_HOME   ${JAVA_HOME}"
echo "SFUSER_HOME ${SFUSER_HOME}"
echo "JBOSS_HOME  ${JBOSS_HOME}"
echo "JAVA_HOME  :  ${JAVA_HOME}" >> $VAR_LOGFILE
echo "SFUSER_HOME:  ${SFUSER_HOME}" >> $VAR_LOGFILE
echo "JBOSS_HOME :  ${JBOSS_HOME}" >> $VAR_LOGFILE

#################################################
# Check for JDK and stop jboss
#################################################
#If already Zing is installed than using Zing. Otherwise using SAP JVM

if [ `echo $JAVA_HOME | grep zingLX | echo $JAVA_HOME | grep zingLX -c` == 1 ]; then
   echo "Zing used!"
   echo "Zing used!" >> $VAR_LOGFILE
   export JDK=ZING
else
   echo "No zing used"
   echo "No zing used" >> $VAR_LOGFILE
   #for using Oracle/Sun JDK
#   export JDK=JDK
   export JDK=SAPJVM
fi
echo "Selected JDK/JVM is ${JDK}"
echo "Selected JDK/JVM is ${JDK}" >> $VAR_LOGFILE

[ -f /etc/init.d/jboss ] && /etc/init.d/jboss stop
killall -9 ${JAVA_HOME}/bin/java
echo "all Java tasks are killed now." >> $VAR_LOGFILE

#################################################
# delete/move already existing files
#################################################
[ -f /etc/init.d/jboss ] && rm -r /etc/init.d/jboss
[ -d /export/home/jboss ] && rm -r /export/home/jboss

[ -f /export/home/jdk1.6.0_39.tar.gz ] && rm -r /export/home/jdk1.6.0_39.tar.gz
[ -h /export/home/jdk6 ] && rm /export/home/jdk6
[ -d /export/home/jdk1.6.0_39 ] && rm -rf /export/home/jdk1.6.0_39

[ -f /export/home/sapjvm6.tar.gz ] && rm -r /export/home/sapjvm6.tar.gz
[ -h /export/home/sapjvm6 ] && rm /export/home/sapjvm6
[ -d /export/home/sapjvm_6 ] && rm -rf /export/home/sapjvm_6

[ -f /export/home/sapjvm7.tar.gz ] && rm -r /export/home/sapjvm7.tar.gz
[ -h /export/home/sapjvm7 ] && rm /export/home/sapjvm7
[ -d /export/home/sapjvm_7 ] && rm -rf /export/home/sapjvm_7

echo "delete/move already existing files are done." >> $VAR_LOGFILE

#################################################
# init.d script for jboss
#################################################
echo copy Jboss initd script
cd /etc/init.d
curl -S -s $REPO_ROOT_AUTH_CURL -O $REPO_ROOT/$REPO_APPENDIX/$LANDSCAPE/jboss/jboss
chmod 755 /etc/init.d/jboss
echo "init.d script for jboss" >> $VAR_LOGFILE

#################################################
# ANT setup
#################################################
echo Download ANT
cd /export/home
#curl -S -s $REPO_ROOT_AUTH_CURL -O $REPO_LANDSCAPE/apache-ant-1.6.1-bin.tgz
curl -S -s $REPO_ROOT_AUTH_CURL -O $REPO_LANDSCAPE/apache-ant-1.8.2-bin.tgz
#tar -zxf apache-ant-1.6.1-bin.tgz
tar -zxf apache-ant-1.8.2-bin.tgz
echo "ANT setup done" >> $VAR_LOGFILE

#################################################
# Sun JDK
#################################################
if [ "$JDK" == "JDK" ]; then
  echo "Download SUN JDK"
  echo "Download SUN JDK" >> $VAR_LOGFILE
  cd /export/home
  curl -S -s $REPO_ROOT_AUTH_CURL -O $REPO_LANDSCAPE/jdk1.6.0_39.tar.gz
  tar -zxf jdk1.6.0_39.tar.gz
  ln -s /export/home/jdk1.6.0_39/ /export/home/jdk6
  echo "Sun JDK installation done" >> $VAR_LOGFILE
  # copy policies files
  echo "Start replacement of policy files" >> $VAR_LOGFILE
  cd /export/home/jdk6/jre/lib/security
  rm US_export_policy.jar local_policy.jar cacerts
  curl -S -s $REPO_ROOT_AUTH_CURL -O $REPO_LANDSCAPE/jdk6_libs/cacerts
  curl -S -s $REPO_ROOT_AUTH_CURL -O $REPO_LANDSCAPE/jdk6_libs/local_policy.jar
  curl -S -s $REPO_ROOT_AUTH_CURL -O $REPO_LANDSCAPE/jdk6_libs/US_export_policy.jar
  chown -R sfuser:jboss /export/home/jdk6/jre/lib/security
  chmod -R 755 /export/home/jdk6/jre/lib/security
  echo "Policy files were replaced" >> $VAR_LOGFILE
fi
#################################################
# SAP JDK (Version 7)
#################################################
if [ "$JDK" == "SAPJVM" ]; then
  echo "Download SAP JVM"
  echo "Download SAP JVM" >> $VAR_LOGFILE
  cd /export/home
  curl -S -s $REPO_ROOT_AUTH_CURL -O $REPO_LANDSCAPE/sapjvm7.tar.gz
  tar -zxf sapjvm7.tar.gz
  chown -R sfuser:jboss /export/home/sapjvm_7/
  chmod -R 755 /export/home/sapjvm_7/
  ln -s /export/home/sapjvm_7/ /export/home/sapjvm7
  echo "SAP JVM installation done" >> $VAR_LOGFILE
  # copy policies files
  echo "Start replacement of policy files" >> $VAR_LOGFILE
  cd /export/home/sapjvm7/jre/lib/security
  rm US_export_policy.jar local_policy.jar cacerts
  echo "REPO_ROOT_AUTH_CURL: ${REPO_ROOT_AUTH_CURL}" >> $VAR_LOGFILE
  echo "REPO_LANDSCAPE     : ${REPO_LANDSCAPE}" >> $VAR_LOGFILE
  curl -S -s $REPO_ROOT_AUTH_CURL -O $REPO_LANDSCAPE/jdk7_libs/cacerts
  curl -S -s $REPO_ROOT_AUTH_CURL -O $REPO_LANDSCAPE/jdk7_libs/local_policy.jar
  curl -S -s $REPO_ROOT_AUTH_CURL -O $REPO_LANDSCAPE/jdk7_libs/US_export_policy.jar
  chown -R sfuser:jboss /export/home/sapjvm7/jre/lib/security
  chmod -R 755 /export/home/sapjvm7/jre/lib/security
  echo "Policy files were replaced" >> $VAR_LOGFILE
fi

#################################################
# Zing JDK
#################################################
if [ "$JDK" == "ZING" ]; then
  echo "Setup Zing JDK"
  echo "Setup Zing JDK" >> $VAR_LOGFILE
  curl -S -s $REPO_ROOT_AUTH_CURL -O $REPO_LANDSCAPE/Zing/zing-zst-5d.2.6.32-5.2.4.0.3.sles11.x86_64.rpm
  curl -S -s $REPO_ROOT_AUTH_CURL -O $REPO_LANDSCAPE/Zing/zing-licensed-5.5.0.0-8.sles11.x86_64.rpm
  curl -S -s $REPO_ROOT_AUTH_CURL -O $REPO_LANDSCAPE/Zing/zingLX-jdk1.6.0_33-5.5.0.0-27.x86_64.rpm
  curl -S -s $REPO_ROOT_AUTH_CURL -O $REPO_LANDSCAPE/Zing/system-config-zing-memory-changed
  
  zypper --non-interactive install zing-zst-5d.2.6.32-5.2.4.0.3.sles11.x86_64.rpm

  cp /usr/sbin/system-config-zing-memory /usr/sbin/system-config-zing-memory-orig
  cp system-config-zing-memory-changed /usr/sbin/system-config-zing-memory
  chmod 755 /usr/sbin/system-config-zing-memory
  /usr/sbin/system-config-zing-memory

  zypper --non-interactive install zing-licensed-5.5.0.0-8.sles11.x86_64.rpm
  zypper --non-interactive install zingLX-jdk1.6.0_33-5.5.0.0-27.x86_64.rpm

  rm zing-zst-5d.2.6.32-5.2.4.0.3.sles11.x86_64.rpm
  rm zing-licensed-5.5.0.0-8.sles11.x86_64.rpm
  rm zingLX-jdk1.6.0_33-5.5.0.0-27.x86_64.rpm
  rm system-config-zing-memory-changed
  echo "Setup Zing JDK installation done" >> $VAR_LOGFILE
fi

#################################################
# JBoss setup
#################################################
echo "Download JBOSS ${JBOSS}"
echo "Download JBOSS ${JBOSS}" >> $VAR_LOGFILE
cd /export/home/
curl -S -s $REPO_ROOT_AUTH_CURL -O $REPO_LANDSCAPE/$JBOSS
echo "Extract ${JBOSS}"
echo "Extract ${JBOSS}" >> $VAR_LOGFILE
if [ "$JBOSS_TYPE" == "SESSION" ]; then
  mkdir jboss
  cd jboss
  tar -zxf ../$JBOSS
#  ln -s /export/home/sessionmgmt/jboss-4.3.0_CP09 /export/home/jboss/jboss-4.3.0
#  ln -s /export/home/jboss/jboss-4.3.0/server/main /export/home/jboss/jboss-4.3.0/server/sfv4Cluster01
elif [ "$JBOSS_TYPE" == "JAMES" ]; then
  tar -zxf $JBOSS
  cd /export/home/james-2.3.2/apps/james/SAR-INF
  curl -S -s $REPO_ROOT_AUTH_CURL -O $REPO_ROOT/$REPO_APPENDIX/$LANDSCAPE/jboss/jboss_type/JAMES/config.xml
  cd /export/home/james-2.3.2/bin
  curl -S -s $REPO_ROOT_AUTH_CURL -O $REPO_ROOT/$REPO_APPENDIX/$LANDSCAPE/jboss/jboss_type/JAMES/phoenix.sh
  cd /export/home/james-2.3.2/lib
  curl -S -s $REPO_ROOT_AUTH_CURL -O $REPO_ROOT/$REPO_APPENDIX/$LANDSCAPE/jboss/jboss_type/JAMES/jamesOauth.jar
  chown -R sfuser:jboss /export/home/james-2.3.2
  chmod -R 755 /export/home/james-2.3.2/
    
  #Note! the /etc/init.d/james file is a link (--> /export/home/james-2.3.2/bin/phoenix.sh) and copied manually 
  #to add system to LVM as instance a link as jboss is added. This is only a workaround. 
  ln -s /export/home/james-2.3.2/bin/phoenix.sh /etc/init.d/jboss
  ln -s /export/home/james-2.3.2/bin/phoenix.sh /etc/init.d/james
  echo >> $VAR_LOGFILE
  echo "Installation of ${JBOSS} is done, please start the Jboss" >> $VAR_LOGFILE
  exit 0
elif [ "$JBOSS_TYPE" == "EMAIL" ]; then
  mkdir jboss
  cd jboss
  tar -zxf $JBOSS
  cd /export/home/jboss/jboss-6.0.0/server/default/deploy/emailengine.war/WEB-INF
  curl -S -s $REPO_ROOT_AUTH_CURL -O $REPO_ROOT/$REPO_APPENDIX/$LANDSCAPE/jboss/jboss_type/EMAIL/applicationContext.xml
  chown sfuser:jboss /export/home/jboss/jboss-6.0.0/server/default/deploy/emailengine.war/WEB-INF/applicationContext.xml
  chmod 777 /export/home/jboss/jboss-6.0.0/server/default/deploy/emailengine.war/WEB-INF/applicationContext.xml
  echo >> $VAR_LOGFILE
  echo "Installation of ${JBOSS} is done, please start the Jboss" >> $VAR_LOGFILE
  exit 0
elif [ "$JBOSS_TYPE" == "HORNET" ]; then
  cd /
  tar -zxf /export/home/$JBOSS
	#unzip $JBOSS -d /export/home/jboss
  chown -R sfuser jboss
  cd /etc/init.d
  curl -S -s $REPO_ROOT_AUTH_CURL -O $REPO_ROOT/$REPO_APPENDIX/$LANDSCAPE/jboss/jboss_type/HORNET/jboss
  echo >> $VAR_LOGFILE
  echo "Installation of ${JBOSS} is done." >> $VAR_LOGFILE
	exit 0
else
  mkdir jboss
  cd jboss
  tar -zxf ../$JBOSS
fi
echo "Jboss setup done" >> $VAR_LOGFILE

#################################################
# CONFIGURATION JBoss
#################################################
echo "Starting Jboss configuration script"
echo "Starting Jboss configuration script" >> $VAR_LOGFILE
cd /export
curl -S -s $REPO_ROOT_AUTH_CURL -O $REPO_SCRIPTS/jboss.config.sh
chmod 755 jboss.config.sh

./jboss.config.sh $LANDSCAPE $JBOSS_TYPE

#################################################
# Deployment JBoss
#################################################
echo "Starting Deplyoment depending on JBOSS_TYPE ${JBOSS_TYPE}"
echo "Starting Deplyoment depending on JBOSS_TYPE ${JBOSS_TYPE}" >> $VAR_LOGFILE

cd /export/home/sfuser
wget $REPO_ROOT_AUTH_WGET $REPO_ROOT/$REPO_APPENDIX/$LANDSCAPE/setup_env.sh
. /export/home/sfuser/setup_env.sh
echo "Reading file setup_env.sh --> Trunk version file is: ${readfiletrunk}"
echo "Reading file setup_env.sh --> Trunk version file is: ${readfiletrunk}" >> $VAR_LOGFILE

wget $REPO_ROOT_AUTH_WGET $REPO_BUILD/${readfiletrunk}
read TRUNK < ./${readfiletrunk}
echo "Trunk version to deploy on system is: ${TRUNK}"
echo "Trunk version to deploy on system is: ${TRUNK}" >> $VAR_LOGFILE

cd /export/home/jboss/jboss-4.3.0/server/sfv4Cluster01/deploy/

if [ "$JBOSS_TYPE" == "CFAPP" ] || [ "$JBOSS_TYPE" == "QUARTZ" ] || [ "$JBOSS_TYPE" == "BIRT" ] || [ "$JBOSS_TYPE" == "BPTSK" ]; then
  # for CFAPP, QUARTZ, BIRT, BPTSK (Business Process Task Execution Server)
  echo "Start deployment for CFAPP or QUARTZ or BIRT"
  echo "Start deployment for CFAPP or QUARTZ or BIRT" >> $VAR_LOGFILE  
  curl -S -s $REPO_ROOT_AUTH_CURL -O $REPO_ROOT/SuccessFactors/Operation/build/$TRUNK/sfv4_$TRUNK.ear
  chown sfuser sfv4_$TRUNK.ear
  echo "sfv4_$TRUNK.ear deployed."
  echo "sfv4_$TRUNK.ear deployed." >> $VAR_LOGFILE
  zypper --non-interactive install openoffice
  echo "Installing OpenOffice package" >> $VAR_LOGFILE 
  zypper --non-interactive install ImageMagick
  echo "Installing ImageMagick package" >> $VAR_LOGFILE 
  ln -s /opt/openoffice4/program/soffice /usr/bin/soffice
  echo "Creating OpenOffice link" >> $VAR_LOGFILE 
elif [ "$JBOSS_TYPE" == "BIPUB" ]; then
  # for BIPUB
  echo "Start deployment for BIPUB"
  echo "Start deployment for BIPUB" >> $VAR_LOGFILE  
  curl -S -s $REPO_ROOT_AUTH_CURL -O $REPO_ROOT/SuccessFactors/Operation/build/$TRUNK/sfv4_$TRUNK.ear
  curl -S -s $REPO_ROOT_AUTH_CURL -O $REPO_ROOT/SuccessFactors/Operation/build/$TRUNK/bipublisher_$TRUNK.ear
  chown sfuser sfv4_$TRUNK.ear
  chown sfuser bipublisher_$TRUNK.ear
  echo "sfv4_$TRUNK.ear deployed."
  echo "sfv4_$TRUNK.ear deployed." >> $VAR_LOGFILE
  echo "bipublisher_$TRUNK.ear deployed."
  echo "bipublisher_$TRUNK.ear deployed." >> $VAR_LOGFILE
elif [ "$JBOSS_TYPE" == "SFAPI" ]; then
  # for SFAPI
  echo "Start deployment for SFAPI"
  echo "Start deployment for SFAPI" >> $VAR_LOGFILE  
  curl -S -s $REPO_ROOT_AUTH_CURL -O $REPO_ROOT/SuccessFactors/Operation/build/$TRUNK/sfv4_sfapi_$TRUNK.ear
  chown sfuser sfv4_sfapi_$TRUNK.ear
  echo "sfv4_sfapi_$TRUNK.ear deployed."
  echo "sfv4_sfapi_$TRUNK.ear deployed." >> $VAR_LOGFILE  
elif [ "$JBOSS_TYPE" == "SOAP" ]; then
  echo "Start deployment for SOAP"
  echo "Start deployment for SOAP" >> $VAR_LOGFILE    
  curl -S -s $REPO_ROOT_AUTH_CURL -O $REPO_ROOT/SuccessFactors/Operation/build/$TRUNK/sfv4_sfapi_$TRUNK.ear
  chown sfuser sfv4_$TRUNK.ear
  echo "sfv4_$TRUNK.ear deployed."
  echo "sfv4_$TRUNK.ear deployed." >> $VAR_LOGFILE    
elif [ "$JBOSS_TYPE" == "AGENCY" ]; then
  # for AGENCY
  echo "Start deployment for AGENCY"
  echo "Start deployment for AGENCY" >> $VAR_LOGFILE    
  curl -S -s $REPO_ROOT_AUTH_CURL -O $REPO_ROOT/SuccessFactors/Operation/build/$TRUNK/sfv4_agency_$TRUNK.ear
  chown sfuser sfv4_agency_$TRUNK.ear
  echo "sfv4_agency_$TRUNK.ear deployed."
  echo "sfv4_agency_$TRUNK.ear deployed." >> $VAR_LOGFILE    
elif [ "$JBOSS_TYPE" == "CAREER" ]; then
  # for CAREER
  echo "Start deployment for CAREER"
  echo "Start deployment for CAREER" >> $VAR_LOGFILE     
  curl -S -s $REPO_ROOT_AUTH_CURL -O $REPO_ROOT/SuccessFactors/Operation/build/$TRUNK/sfv4_career_$TRUNK.ear
  curl -S -s $REPO_ROOT_AUTH_CURL -O $REPO_ROOT/SuccessFactors/Operation/build/$TRUNK/bipublisher_$TRUNK.ear
  chown sfuser sfv4_career_$TRUNK.ear
  chown sfuser bipublisher_$TRUNK.ear
  echo "sfv4_career_$TRUNK.ear deployed."
  echo "sfv4_career_$TRUNK.ear deployed." >> $VAR_LOGFILE      
  echo "bipublisher_$TRUNK.ear deployed."
  echo "bipublisher_$TRUNK.ear deployed." >> $VAR_LOGFILE      
elif [ "$JBOSS_TYPE" == "REPORT" ] || [ "$JBOSS_TYPE" == "JMS" ] || [ "$JBOSS_TYPE" == "SCHED" ]; then
  # for REPORT, JMS, SCHED
  echo "Start deployment for REPORT or JMS or SCHED" 
  echo "Start deployment for REPORT or JMS or SCHED" >> $VAR_LOGFILE    
  curl -S -s $REPO_ROOT_AUTH_CURL -O $REPO_ROOT/SuccessFactors/Operation/build/$TRUNK/sfv4_$TRUNK.ear
  chown sfuser sfv4_$TRUNK.ear
  echo "sfv4_$TRUNK.ear deployed."
  echo "sfv4_$TRUNK.ear deployed." >> $VAR_LOGFILE       
elif [ "$JBOSS_TYPE" == "EBS" ]; then
  # for EBS
  echo "Start deployment for EBS"
  echo "Start deployment for EBS" >> $VAR_LOGFILE    
  curl -S -s $REPO_ROOT_AUTH_CURL -O $REPO_ROOT/SuccessFactors/Operation/build/$TRUNK/sfv4_$TRUNK.ear
  curl -S -s $REPO_ROOT_AUTH_CURL -O $REPO_ROOT/SuccessFactors/Operation/build/$TRUNK/seb_$TRUNK.ear
  chown sfuser sfv4_$TRUNK.ear
  chown sfuser seb_$TRUNK.ear
  echo "sfv4_$TRUNK.ear deployed."
  echo "sfv4_$TRUNK.ear deployed." >> $VAR_LOGFILE         
  echo "seb_$TRUNK.ear deployed."
  echo "seb_$TRUNK.ear deployed." >> $VAR_LOGFILE         
elif [ "$JBOSS_TYPE" == "SEARCHUPD" ] || [ "$JBOSS_TYPE" == "SEARUPD" ]; then
  # for SEARCHUPD
  echo "Start deployment for SEARCHUPD" 
  echo "Start deployment for SEARCHUPD" >> $VAR_LOGFILE     
  curl -S -s $REPO_ROOT_AUTH_CURL -O $REPO_BUILD/$TRUNK/sfv4_$TRUNK.ear
  curl -S -s $REPO_ROOT_AUTH_CURL -O $REPO_ROOT/$REPO_APPENDIX/$LANDSCAPE/jboss/deploy/search_solr3.war
  mv search_solr3.war search.war
  chown sfuser sfv4_$TRUNK.ear
  chown sfuser search.war
  echo "sfv4_$TRUNK.ear deployed."
  echo "sfv4_$TRUNK.ear deployed." >> $VAR_LOGFILE    
  echo "search.war for solr3 deployed."
  echo "search.war for solr3 deployed." >> $VAR_LOGFILE    
  # install solr3 search
  cd /export/home
  curl -S -s $REPO_ROOT_AUTH_CURL -O $REPO_LANDSCAPE/solr3-V1.tgz
  cd /export/home/jboss/jboss-4.3.0/server/sfv4Cluster01/
  tar -zxf /export/home/solr3-V1.tgz
  echo "Solr3 search files installed"
  echo "Solr3 search files installed" >> $VAR_LOGFILE     
  echo "Please run a configuration via LVM too!"
  echo "Please run a configuration via LVM too!" >> $VAR_LOGFILE     
elif [ "$JBOSS_TYPE" == "SEARCHQRY" ]; then
  # for SEARCHQRY
  echo "Start deployment for SEARCHQRY"
  echo "Start deployment for SEARCHQRY" >> $VAR_LOGFILE    
  curl -S -s $REPO_ROOT_AUTH_CURL -O $REPO_ROOT/$REPO_APPENDIX/$LANDSCAPE/jboss/deploy/search_solr3.war
  mv search_solr3.war search.war
  chown sfuser search.war
  echo "search.war for solr3 file deployed."
  echo "search.war for solr3 file deployed." >> $VAR_LOGFILE       
  # install solr3 search
  cd /export/home
  curl -S -s $REPO_ROOT_AUTH_CURL -O $REPO_LANDSCAPE/solr3-V1.tgz
  cd /export/home/jboss/jboss-4.3.0/server/sfv4Cluster01/
  tar -zxf /export/home/solr3-V1.tgz
  echo "Solr3 search files installed"
  echo "Solr3 search files installed" >> $VAR_LOGFILE    
  echo "Please run a configuration via LVM too!"
  echo "Please run a configuration via LVM too!" >> $VAR_LOGFILE       
elif [ "$JBOSS_TYPE" == "SEARCH" ]; then
  # for SEARCH (solr4)
  echo "Start deployment for SEARCH (solr4)"
  echo "Start deployment for SEARCH (solr4)" >> $VAR_LOGFILE     
  #for solr4
  curl -S -s $REPO_ROOT_AUTH_CURL -O $REPO_ROOT/$REPO_APPENDIX/$LANDSCAPE/jboss/deploy/search.war
  chown sfuser search.war
  echo "search.war file deployed."
  echo "search.war file deployed." >> $VAR_LOGFILE       
  # install solr4 search
  cd /export/home
  curl -S -s $REPO_ROOT_AUTH_CURL -O $REPO_LANDSCAPE/solr4-V1.tgz
  cd /export/home/jboss/jboss-4.3.0/server/sfv4Cluster01/
  tar -zxf /export/home/solr4-V1.tgz
  echo "Solr4 search files installed"
  echo "Solr4 search files installed" >> $VAR_LOGFILE      
  echo "Please run a configuration via LVM too!"
  echo "Please run a configuration via LVM too!" >> $VAR_LOGFILE       
elif [ "$JBOSS_TYPE" == "IMG" ] || [ "$JBOSS_TYPE" == "ATTACH" ]; then
  # for IMG, ATTACH
  echo "Start deployment for IMG or ATTACH"
  echo "Start deployment for IMG or ATTACH" >> $VAR_LOGFILE        
  curl -S -s $REPO_ROOT_AUTH_CURL -O $REPO_ROOT/SuccessFactors/Operation/build/$TRUNK/sfv4_$TRUNK.ear
  chown sfuser sfv4_$TRUNK.ear
  echo "sfv4_$TRUNK.ear deployed."
  echo "sfv4_$TRUNK.ear deployed." >> $VAR_LOGFILE     
  zypper --non-interactive install openoffice
  echo "Installing OpenOffice package" >> $VAR_LOGFILE 
  zypper --non-interactive install ImageMagick
  echo "Installing ImageMagick package" >> $VAR_LOGFILE   
elif [ "$JBOSS_TYPE" == "SESSION" ]; then
  # for SESSION
  echo "Start deployment for SESSION"
  echo "Start deployment for SESSION" >> $VAR_LOGFILE      
  curl -S -s $REPO_ROOT_AUTH_CURL -O $REPO_ROOT/SuccessFactors/Operation/build/$TRUNK/sessionmgmt_$TRUNK.ear
  chown sfuser sessionmgmt_$TRUNK.ear
  echo "sessionmgmt_$TRUNK.ear deployed."
  echo "sessionmgmt_$TRUNK.ear deployed." >> $VAR_LOGFILE  
#elif [ "$JBOSS_TYPE" == "CACHECONFIG" ]; then
  # for CACHECONFIG
  #[ -d /export/home/cacheconfig_backup ] || mkdir /export/home/cacheconfig_backup
else
  echo "Jboss_Type ${JBOSS_TYPE} not matching -> no deployment will be performed!"
  echo "Jboss_Type ${JBOSS_TYPE} not matching -> no deployment will be performed!" >> $VAR_LOGFILE       
fi

chown -R sfuser:jboss /export/home/jboss/

# Jboss start is done by LVM
#/etc/init.d/jboss start
echo "Please start a deployment by LVM" >> $VAR_LOGFILE
echo >> $VAR_LOGFILE

echo "--- end of script --- ["`date +%F` - `date +%R`"]" >> $VAR_LOGFILE