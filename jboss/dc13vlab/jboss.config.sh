#!/bin/bash

##################################################################
### SAP BizX configuration script
###
### Calling: ./jboss.config.sh <landscape> <jboss type> 
### <landscape>  => one of QACAND2, QAPATCH2,...
### <jboss type> => one of CFAPP,SFAPI,QUARZ,...
### e.g. 
### <landscape>  = QAPATCH2
### <jboss type> = CFAPP
### jboss.config.sh QAPATCH2 vsa123456 CF
###
###################################################################


case "$1" in 
   QAPATCH2|QACAND2|QAAUTOCAND|QACAND|BIZX2|DC13QAPH|QAAUTOPH|DC13PFHA|DC12PRD1|PERFLOAD|PERFSANITY|QARMDA|MONSOON|QAUPGR|QAVERIHANA);;
   *)   echo "Landscape $1 does not match with permitted."
        echo "e.g.  ./jboss.config.sh QACAND2 CFAPP"
        exit 1;;
esac

if [ "$2" == "" ]; then
  echo "The 'jboss type' is missing!"
  echo "Calling: ./copy.config.jboss <landscape = [QACAND or QAAUTOCANDor QACAND2 or QAPATCH2 or DC12PRD1]> <jboss type = [CFAPP or SFAPI or QUARZ or REPORT ...]>"
  echo "<jboss type> = CFAPP , SFAPI, QUARTZ, REPORT, SEARCHUPD, SEARCHQRY, JMS, CAREER, BIRT, ATTACH, AGENCY, IMG"
  echo "e.g.  ./jboss.config.sh DC12PRD1 CFAPP"
  exit 1
fi

#################################################
# Define environment
#################################################
export LANDSCAPE=$1
export JBOSS_TYPE=$2

export CONFIG_ROOT="/export/home/config"

export REPO_HOST="repo:50000"
export REPO_ROOT="http://$REPO_HOST/repo"
export REPO_BUILD=$REPO_ROOT/SuccessFactors/Operation/build

#different repositories
if [ "$LANDSCAPE" == "DC12PRD1" ]; then
  export REPO_APPENDIX="SuccessFactorsProduction/DC12"
  export REPO_LANDSCAPE=$REPO_ROOT/$REPO_APPENDIX/landscape
  export REPO_SCRIPTS=$REPO_ROOT/$REPO_APPENDIX/scripts
  #export REPO_ROOT_AUTH_WGET="--user=xxx --password='xxx'"
  #export REPO_ROOT_AUTH_CURL="--user=xxx --password='xxx'"
  # export TRUNK="b1302.0000_QAPATCH"
elif [ "$LANDSCAPE" == "QACAND" ] || [ "$LANDSCAPE" == "QAAUTOCAND" ] || [ "$LANDSCAPE" == "QAPATCH2" ] || [ "$LANDSCAPE" == "BIZX2" ] || [ "$LANDSCAPE" == "DC13QAPH" ] || [ "$LANDSCAPE" == "QAAUTOPH" ] || [ "$LANDSCAPE" == "DC13PFHA" ] || [ "$LANDSCAPE" == "PERFLOAD" ] || [ "$LANDSCAPE" == "PERFSANITY" ] || [ "$LANDSCAPE" == "QAUPGR" ] || [ "$LANDSCAPE" == "QAVERIHANA" ]; then
  export REPO_APPENDIX="SuccessFactors/Operation/config/QA/DC13/BizX"
  export REPO_LANDSCAPE=$REPO_ROOT/SuccessFactors/Operation/config/global/landscape
  export REPO_SCRIPTS=$REPO_ROOT/SuccessFactors/Operation/config/QA/DC13/global
elif [ "$LANDSCAPE" == "QARMDA" ]; then
  export REPO_APPENDIX="SuccessFactors/Operation/config/QA/DEV/BizX"
  export REPO_LANDSCAPE=$REPO_ROOT/SuccessFactors/Operation/config/global/landscape
  export REPO_SCRIPTS=$REPO_ROOT/SuccessFactors/Operation/config/QA/DC13/global
elif [ "$LANDSCAPE" == "MONSOON" ]; then
  export REPO_APPENDIX="SuccessFactors/Operation/config/QA/DEV/BizX"
  export REPO_LANDSCAPE=$REPO_ROOT/SuccessFactors/Operation/config/global/landscape
  export REPO_SCRIPTS=$REPO_ROOT/SuccessFactors/Operation/config/QA/DC13/global
else
  export REPO_ROOT="unknown"
  echo "ERROR - no REPO_ROOT defined for ${LANDSCAPE}!"
  exit 1
fi

#################################################
# Check for Script changes
#################################################
cd /export
mv jboss.config.sh jboss.config.sh.old
curl -S -s $REPO_ROOT_AUTH_CURL -O $REPO_SCRIPTS/jboss.config.sh
chmod 755 jboss.config.sh
diff jboss.config.sh.old jboss.config.sh 
if [ "$?" == 1 ]; then
  echo File jboss.config.sh changed, please restart.
  rm jboss.config.sh.old
  exit 1
fi
rm jboss.config.sh.old

#################################################
# Check user
#################################################
if ! [ "$(id -u)" = 0 ]; then
  echo Please run as user root
  exit 1
fi

#################################################
# copyfile
# delete/move already existing files
# owner $1 source $2, dest. $3
#################################################
copyfile () {
  [ -f $3 ] && mv $3 $3.`date +%F`.`date +%R`
  cp --remove-destination $2 $3
  RET=$?
  chown $1 $3
  echo `date +%F`.`date +%R` $RET COPY $1 TO $2 >> copyconfig.log
  echo "COPY File: $RET -  $2  TO  $3" 
}
copyfileforce () {
  [ -f $3 ] && rm -r $3
  cp --remove-destination $2 $3
  RET=$?
  chown $1 $3
  echo `date +%F`.`date +%R` $RET COPY $1 TO $2 >> copyconfig.log
  echo "COPY File: $RET -  $2  TO  $3"
}

#################################################
# Load sfuser environment (JAVA_HOME)
#################################################
. /export/home/sfuser/.bash_profile
echo "JAVA_HOME  : $JAVA_HOME"
echo "SFUSER_HOME: $SFUSER_HOME"
echo "JBOSS_HOME : $JBOSS_HOME"

#################################################
# Download configuration
#################################################
cd $SFUSER_HOME

if [ -d tmp.repo ]; then 
  rm -r tmp.repo
fi
if [ -d tmp.config ]; then 
  rm -r tmp.config
fi

wget -r $REPO_ROOT_AUTH_WGET $REPO_ROOT/$REPO_APPENDIX/$LANDSCAPE/ -q -np -l10 -P tmp.repo
mkdir -p tmp.config
mv "tmp.repo/$REPO_HOST/repo/$REPO_APPENDIX/$LANDSCAPE" ./tmp.config/$LANDSCAPE

[ -d tmp.repo ] && rm -r tmp.repo
find tmp.config/$LANDSCAPE -name "index.html*" -exec rm {} \;

export CP_OPTS="--remove-destination"

# .bash_profile
#[ -f /export/home/sfuser/.bash_profile ] && rm /export/home/sfuser/.bash_profile
copyfile sfuser:jboss tmp.config/$LANDSCAPE/jboss/bash_profile /export/home/sfuser/.bash_profile

#jboss type specific
[ -f ${JBOSS_HOME}/server/main/run.conf ] && rm ${JBOSS_HOME}/server/main/run.conf
copyfile sfuser:jboss tmp.config/$LANDSCAPE/jboss/jboss_type/$JBOSS_TYPE/run.conf ${JBOSS_HOME}/server/main/run.conf
[ -f ${JBOSS_HOME}/server/main/run.conf.global ] && rm ${JBOSS_HOME}/server/main/run.conf.global
copyfile sfuser:jboss tmp.config/$LANDSCAPE/jboss/jboss_type/run.conf.global ${JBOSS_HOME}/server/main/run.conf.global


# /bin
copyfile sfuser:jboss tmp.config/$LANDSCAPE/jboss/base/setClusterEnv.sh ${JBOSS_HOME}/bin/setClusterEnv.sh
copyfile sfuser:jboss tmp.config/$LANDSCAPE/jboss/base/startCluster.sh ${JBOSS_HOME}/bin/startCluster.sh
copyfile sfuser:jboss tmp.config/$LANDSCAPE/jboss/base/stopCluster.sh ${JBOSS_HOME}/bin/stopCluster.sh
copyfile sfuser:jboss tmp.config/$LANDSCAPE/jboss/base/stopConnectors.sh ${JBOSS_HOME}/bin/stopConnectors.sh
chmod 755  ${JBOSS_HOME}/bin/setClusterEnv.sh ${JBOSS_HOME}/bin/startCluster.sh ${JBOSS_HOME}/bin/stopCluster.sh  ${JBOSS_HOME}/bin/stopConnectors.sh

# /server/main/conf/oiosaml-conf
rm -r ${JBOSS_HOME}/server/main/conf/oiosaml-conf
cp $CP_OPTS -r tmp.config/$LANDSCAPE/jboss/conf/oiosaml-conf ${JBOSS_HOME}/server/main/conf/oiosaml-conf

# /server/main/deploy
copyfileforce sfuser:jboss tmp.config/$LANDSCAPE/jboss/deploy/jbossjca-service.xml ${JBOSS_HOME}/server/main/deploy/jbossjca-service.xml
copyfileforce sfuser:jboss tmp.config/$LANDSCAPE/jboss/deploy/hsqldb-ds.xml ${JBOSS_HOME}/server/main/deploy/hsqldb-ds.xml

#cp $CP_OPTS tmp.config/$LANDSCAPE/jboss/deploy/qa-oracle-ds.xml ${JBOSS_HOME}/server/main/deploy/qa-oracle-ds.xml
#cp $CP_OPTS tmp.config/$LANDSCAPE/jboss/deploy/qa-oracle-non-tx-ds.xml ${JBOSS_HOME}/server/main/deploy/qa-oracle-non-tx-ds.xml
copyfileforce sfuser:jboss tmp.config/$LANDSCAPE/jboss/deploy/sfbizx-oracle-ds.xml ${JBOSS_HOME}/server/main/deploy/sfbizx-oracle-ds.xml
copyfileforce sfuser:jboss tmp.config/$LANDSCAPE/jboss/deploy/sfbizx-HANA-ds.xml ${JBOSS_HOME}/server/main/deploy/sfbizx-HANA-ds.xml
copyfileforce sfuser:jboss tmp.config/$LANDSCAPE/jboss/deploy/sfbizx-oracle-non-tx-ds.xml ${JBOSS_HOME}/server/main/deploy/sfbizx-oracle-non-tx-ds.xml
copyfileforce sfuser:jboss tmp.config/$LANDSCAPE/jboss/deploy/sfbizx-HANA-non-tx-ds.xml ${JBOSS_HOME}/server/main/deploy/sfbizx-HANA-non-tx-ds.xml

copyfileforce sfuser:jboss tmp.config/$LANDSCAPE/jboss/deploy/jboss-web.deployer/jbossweb.jar ${JBOSS_HOME}/server/main/deploy/jboss-web.deployer/jbossweb.jar
copyfileforce sfuser:jboss tmp.config/$LANDSCAPE/jboss/deploy/jboss-web.deployer/server.xml ${JBOSS_HOME}/server/main/deploy/jboss-web.deployer/server.xml
mkdir -p ${JBOSS_HOME}/server/main/deploy/jboss-web.deployer/conf
chown sfuser:jboss ${JBOSS_HOME}/server/main/deploy/jboss-web.deployer/conf
copyfileforce sfuser:jboss tmp.config/$LANDSCAPE/jboss/deploy/jboss-web.deployer/web.xml ${JBOSS_HOME}/server/main/deploy/jboss-web.deployer/conf/web.xml

# /server/main/lib
copyfileforce sfuser:jboss tmp.config/$LANDSCAPE/jboss/lib/ngdbc.jar ${JBOSS_HOME}/server/main/lib/ngdbc.jar

if ! [ "$JBOSS_TYPE" = "SESSION" ]; then
  # /server/main/conf
  copyfile sfuser:jboss tmp.config/$LANDSCAPE/jboss/conf/jndiclient.xml ${JBOSS_HOME}/server/main/conf/jndiclient.xml
  copyfile sfuser:jboss tmp.config/$LANDSCAPE/jboss/conf/jbossjta-properties.xml ${JBOSS_HOME}/server/main/conf/jbossjta-properties.xml
  copyfile sfuser:jboss tmp.config/$LANDSCAPE/jboss/conf/jboss-log4j.xml ${JBOSS_HOME}/server/main/conf/jboss-log4j.xml
  copyfile sfuser:jboss tmp.config/$LANDSCAPE/jboss/conf/sourceid-core-config.xml ${JBOSS_HOME}/server/main/conf/sourceid-core-config.xml
  copyfile sfuser:jboss tmp.config/$LANDSCAPE/jboss/conf/sourceid-application-directory.xml ${JBOSS_HOME}/server/main/conf/sourceid-application-directory.xml
  copyfile sfuser:jboss tmp.config/$LANDSCAPE/jboss/conf/jboss-service.xml ${JBOSS_HOME}/server/main/conf/jboss-service.xml
  copyfile sfuser:jboss tmp.config/$LANDSCAPE/jboss/conf/scheduler.properties ${JBOSS_HOME}/server/main/conf/scheduler.properties
  copyfile sfuser:jboss tmp.config/$LANDSCAPE/jboss/conf/sf-quartz1.properties ${JBOSS_HOME}/server/main/conf/sf-quartz1.properties
  copyfile sfuser:jboss tmp.config/$LANDSCAPE/jboss/conf/sfkeystore.properties ${JBOSS_HOME}/server/main/conf/sfkeystore.properties
  ## next 3 not in QA?
  copyfile sfuser:jboss tmp.config/$LANDSCAPE/jboss/conf/client-config.xml ${JBOSS_HOME}/server/main/conf/client-config.xml
  copyfile sfuser:jboss tmp.config/$LANDSCAPE/jboss/conf/search.properties ${JBOSS_HOME}/server/main/conf/search.properties
  copyfile sfuser:jboss tmp.config/$LANDSCAPE/jboss/conf/sfserver.properties ${JBOSS_HOME}/server/main/conf/sfserver.properties
fi

# Zing /opt/zing/zingLX-jdk1.6.0_33-5.5.0.0-27-x86_64/jre/lib/security/
#copyfile root:root tmp.config/$LANDSCAPE/jdk/libs/local_policy.jar $JAVA_HOME/jre/lib/security/local_policy.jar
#chmod 644 $JAVA_HOME/jre/lib/security/local_policy.jar
#copyfile root:root tmp.config/$LANDSCAPE/jdk/libs/US_export_policy.jar $JAVA_HOME/jre/lib/security/US_export_policy.jar
#chmod 644 $JAVA_HOME/jre/lib/security/US_export_policy.jar
#copyfile root:root tmp.config/$LANDSCAPE/jdk/libs/cacerts $JAVA_HOME/jre/lib/security/cacerts
#copyfile root:root tmp.config/$LANDSCAPE/jdk/zing/license /etc/zing/license
#chmod 644 /etc/zing/license
#chown -R sfuser:jboss $JAVA_HOME/jre/lib/security/

cd $SFUSER_HOME
if [ -d tmp.repo ]; then 
  rm -r tmp.repo
fi
if [ -d tmp.config ]; then 
  rm -r tmp.config
fi

echo "copy of configuration files is done!"

exit 0
