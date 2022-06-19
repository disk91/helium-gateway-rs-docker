#!/bin/bash

TARGET_DIR=/opt/helium_gateway

if [ ! -d ${TARGET_DIR} ] ; then
  # No directory mounted, better to exit than creating IDs inside a container
  echo "You must mount a persistent directory for /opt/helium_gateway"
  exit 1
fi


if [ ! -f ${TARGET_DIR}/default.toml ] ; then
  # The container has not been initialized
  # move the configuration file to the external directory
  echo "Initializing gateway rs"
  cp -R /etc/helium_gateway/* ${TARGET_DIR}/
  
  # Add the ZONE in file
  if [ ! -z "${HELIUM_RS_ZONE}" ] ; then
    echo "Setting up Zone for ${HELIUM_RS_ZONE}"
    mv ${TARGET_DIR}/settings.toml ${TARGET_DIR}/settings.bak
    (echo "region=\"${HELIUM_RS_ZONE}\"" ; cat ${TARGET_DIR}/settings.bak ) > ${TARGET_DIR}/settings.toml
  fi
  if [ ! -z "${HELIUM_RS_UPDATE}" ] ; then
    echo "Setting up auto update status ${HELIUM_RS_UPDATE}"
    mv ${TARGET_DIR}/settings.toml ${TARGET_DIR}/settings.bak
    ( cat ${TARGET_DIR}/settings.bak ; echo "enabled=${HELIUM_RS_UPDATE}" ) > ${TARGET_DIR}/settings.toml
  fi 
  # Change the logger
  mv ${TARGET_DIR}/settings.toml ${TARGET_DIR}/settings.bak
  cat ${TARGET_DIR}/settings.bak | sed -e 's/syslog/stdio/' > ${TARGET_DIR}/settings.toml
  rm ${TARGET_DIR}/settings.bak

  # Change the listener
  mv ${TARGET_DIR}/settings.toml ${TARGET_DIR}/settings.bak
  cat ${TARGET_DIR}/settings.bak | sed -e 's/listen_addr/listen/' > ${TARGET_DIR}/settings.toml
  rm ${TARGET_DIR}/settings.bak

  # Change the key path
  mv ${TARGET_DIR}/settings.toml ${TARGET_DIR}/settings.bak
  ( echo "keypair = \"${TARGET_DIR}/gateway_key.bin\"" ; cat ${TARGET_DIR}/settings.bak ) > ${TARGET_DIR}/settings.toml
  rm ${TARGET_DIR}/settings.bak

  /usr/bin/helium_gateway -c ${TARGET_DIR} server &
  sleep 3

  # Make the gateway key to be created
  /usr/bin/helium_gateway -c ${TARGET_DIR} key info
  GWNAME=`/usr/bin/helium_gateway -c ${TARGET_DIR} key info | grep name | tr -s " " | cut -d ':' -f 2 | sed -e 's/[ \"]//g'` 
  touch ${TARGET_DIR}/$GWNAME

  # Display the registration transaction
  if [ ! -z "${HELIUM_RS_OWNER}" ] && [ ! -z "${HELIUM_RS_PAYER}" ] ; then
   /usr/bin/helium_gateway -c ${TARGET_DIR} add --owner ${HELIUM_RS_OWNER}  --payer ${HELIUM_RS_PAYER}
  fi 
else

   # resync the default.toml file
   if ! diff /etc/helium_gateway/default.toml ${TARGET_DIR}/default.toml ; then
      echo "update default.toml"
      cp ${TARGET_DIR}/default.toml ${TARGET_DIR}/default.toml.bak
      cp /etc/helium_gateway/default.toml ${TARGET_DIR}/default.toml
   fi

   # Process to configuration file update
   # start from version 0.21 - this one should not be executed anymore
   #if ! grep "api.*4476" ${TARGET_DIR}/default.toml >/dev/null 2>/dev/null ; then
   #  echo "update to beta-22"
   #  cp ${TARGET_DIR}/default.toml ${TARGET_DIR}/default.toml.bak
   #  sed '/^listen.*/a api=4476' ${TARGET_DIR}/default.toml.bak > ${TARGET_DIR}/default.toml 
   #fi    

   /usr/bin/helium_gateway -c ${TARGET_DIR} server
fi 
