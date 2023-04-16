#!/bin/bash

TARGET_DIR=/opt/helium_gateway
BIN_DIR=/opt/gateway-rs

if [ ! -d ${TARGET_DIR} ] ; then
  # No directory mounted, better to exit than creating IDs inside a container
  echo "You must mount a persistent directory for /opt/helium_gateway"
  exit 1
fi

if [ -f ${BIN_DIR}/v1.0.2 ] ; then
  # New version 1.0.2
  if [ ! -f ${TARGET_DIR}/default.toml ] ; then
   # Backup previous Setting file if previous config exists
   mv ${TARGET_DIR}/settings.toml ${TARGET_DIR}/settings.toml.v0.0.x
   mv ${TARGET_DIR}/default.toml ${TARGET_DIR}/default.toml.v0.0.x
  fi
  # Create config file is not existing
  if [ ! -f ${TARGET_DIR}/settings.toml ] ; then
   # Get it from the binary directory
   cp ${BIN_DIR}/settings.toml ${TARGET_DIR}/settings.toml
   # Update the file
   # Add the ZONE in file
   if [ ! -z "${HELIUM_RS_ZONE}" ] ; then
    echo "Setting up Zone for ${HELIUM_RS_ZONE}"
    mv ${TARGET_DIR}/settings.toml ${TARGET_DIR}/settings.bak
    (echo "region=\"${HELIUM_RS_ZONE}\"" ; cat ${TARGET_DIR}/settings.bak ) > ${TARGET_DIR}/settings.toml
   fi
   # Change the listener
   mv ${TARGET_DIR}/settings.toml ${TARGET_DIR}/settings.bak
   cat ${TARGET_DIR}/settings.bak | sed -e 's/listen = "127.0.0.1:1680"/listen = "0.0.0.0:1680"/' > ${TARGET_DIR}/settings.toml
   rm ${TARGET_DIR}/settings.bak

   # Change the key path
   mv ${TARGET_DIR}/settings.toml ${TARGET_DIR}/settings.bak
   cat ${TARGET_DIR}/settings.bak | sed -e "s@/etc/helium_gateway/gateway_key.bin@${TARGET_DIR}/gateway_key.bin@" > ${TARGET_DIR}/settings.toml
   rm ${TARGET_DIR}/settings.bak

   # is that a new instance ?
   if [ ! -f ${TARGET_DIR}/gateway_key.bin ] ; then
     ${BIN_DIR}/helium_gateway -c ${TARGET_DIR} server &
     sleep 3

     # Get the key information
     ${BIN_DIR}/helium_gateway -c ${TARGET_DIR} key info
     GWNAME=`/usr/bin/helium_gateway -c ${TARGET_DIR} key info | grep name | tr -s " " | cut -d ':' -f 2 | sed -e 's/[ \"]//g'`
     touch ${TARGET_DIR}/$GWNAME

     # Display the registration transaction
     if [ ! -z "${HELIUM_RS_OWNER}" ] && [ ! -z "${HELIUM_RS_PAYER}" ] ; then
       ${BIN_DIR}/helium_gateway -c ${TARGET_DIR} add --owner ${HELIUM_RS_OWNER}  --payer ${HELIUM_RS_PAYER}
     fi
   else
     # run a previously created gateway-rs
     ${BIN_DIR}/helium_gateway -c ${TARGET_DIR} server
   fi
  else
    # normal case, restarting a gateway-rs
    ${BIN_DIR}/helium_gateway -c ${TARGET_DIR} server
  fi
fi

