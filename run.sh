#!/bin/bash
# (c) disk91 / Paul Pinault
# GPLv3
# see - https://github.com/disk91/helium-gateway-rs-docker

# default values
CONFDIR=""
CONFIGURED=0
PORT=0
ZONE=US915
OWNER=""
PAYER=""
UPDATE=true

function help {
    echo "Start an Helium gateway-rs as a docker container"
    echo "-c | --config-dir config_directory - setup the configuration directory (empty directory when adding a new one)"
    echo " "
    echo "Following configuration is needed for the creation of a new gateway"
    echo "-p | --port nnnn - select the udp port to be used for this gateway-rs"
    echo "-z | --zone XXXXX - select the zone"
    echo "-o | --owner xxxxx..xxxx - Owner and Payer waller for creating the registration transaction reference"
    echo "-u | --update true/false - Enable gateway rs auto-update default true"
    exit 0
}


# process command line
while [[ $# -gt 0 ]]; do
  key="$1"

  case $key in
   -h|--help)
    help
    ;;
   -c|--config-dir)
    CONFDIR="$2"
    if [ ! -d ${CONFDIR} ] ; then
      echo "Invalid configuration directory"
      exit 1
    fi
    if [ -f ${CONFDIR}/settings.toml ] ; then
      CONFIGURED=1
    fi
    shift
    ;;
   -p|--port)
    PORT="$2"
    shift 
    ;; 
   -z|--zone)
    ZONE="$2"
    shift
    ;;
   -o|--owner)
    OWNER="$2"
    PAYER="$2"
    shift
    ;; 
   -u|--update)
    UPDATE="$2"
    if [ ${UPDATE} != "true" ] && [ ${UPDATE} != "false" ] ; then
      echo "Invalid value for update switch"
      help
    fi
    shift
    ;;
  esac
  shift
done

# Verify mandatory parameters
if [ -z ${CONFDIR} ] ; then
  echo "Invalid configuration directory"
  help
fi

CONFDIR=`realpath ${CONFDIR}`
CONTAINERNAME=helium-rs`echo ${CONFDIR} | sed -e 's/\//-/g'`

if [ ${CONFIGURED} -eq 0 ] ; then
  # new gateway, configuration is needed
  if [ ${PORT} -eq 0 ] ; then
    echo "Invalid port number"
    help
  fi

  # save the configuration
  echo "${PORT}" > ${CONFDIR}/port

  # run the container for the first time
  docker run --name ${CONTAINERNAME} \
   --restart always \
   -p ${PORT}:1680/udp \
   -v ${CONFDIR}:/opt/helium_gateway \
   -e HELIUM_RS_ZONE=${ZONE} \
   -e HELIUM_RS_UPDATE=${UPDATE} \
   -e HELIUM_RS_OWNER=${OWNER} \
   -e HELIUM_RS_PAYER=${PAYER} \
   -d gateway-rs 
  sleep 2
  docker logs ${CONTAINERNAME} 

else

  # restart a container previously configured
  PORT=`cat ${CONFDIR}/port`
  docker stop ${CONTAINERNAME}
  docker rm ${CONTAINERNAME}
  docker run --name ${CONTAINERNAME} \
   --restart always \
   -p ${PORT}:1680/udp \
   -v ${CONFDIR}:/opt/helium_gateway \
   -d gateway-rs  

fi
