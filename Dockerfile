ARG SYSTEM_TIMEZONE="Europe/London"

FROM ubuntu:latest

WORKDIR /opt/gateway-rs
ENV VERSION=v1.0.0-alpha.28

# Install dependencies 
RUN \
	apt-get update && \
        DEBIAN_FRONTEND="noninteractive" \
	TZ="$SYSTEM_TIMEZONE" \
	apt-get -y install wget python3 ca-certificates curl && \
	apt-get autoremove -y && \
	apt-get clean && \ 
	rm -rf /var/lib/apt/lists/*

# Install getway-rs 
RUN wget https://github.com/helium/gateway-rs/releases/download/${VERSION}/helium-gateway-${VERSION}-x86_64.deb
RUN dpkg -i helium-gateway-*-x86_64.deb

# Copy startup script 
COPY startScript.sh .
RUN chmod +x startScript.sh

ENTRYPOINT ["/opt/gateway-rs/startScript.sh"]
