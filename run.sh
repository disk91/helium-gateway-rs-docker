#!/bin/bash

docker stop helium-rs
docker rm helium-rs

docker run -it --name helium-rs \
   	-v /opt/rs/gw1:/opt/helium_gateway \
	-e HELIUM_RS_ZONE=EU868 \
 	-e HELIUM_RS_UPDATE=false \
	-e HELIUM_RS_OWNER='13ZhVBrEJLAaHKQ2vKZPFAxyAMqxd2726UhSFzDWXpGEizSUixU' \
 	-e HELIUM_RS_PAYER='13ZhVBrEJLAaHKQ2vKZPFAxyAMqxd2726UhSFzDWXpGEizSUixU' \
	-d gateway-rs /bin/bash 
sleep 2
docker logs helium-rs	
