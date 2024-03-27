FROM ubuntu:24.04

# Build arguments
ARG DEBIAN_FRONTEND=noninteractive
ARG EULA=false
ARG NEOFORGE_VERSION
ARG MODPACK_VERSION

# Update the system
RUN apt-get update -y
RUN apt-get upgrade -y

WORKDIR /tmp

# Install the required packages
RUN apt-get install openjdk-17-jdk openjdk-17-jre -y --no-install-recommends
RUN apt-get install build-essential -y --no-install-recommends
RUN apt-get install wget -y --no-install-recommends
RUN apt-get install unzip -y --no-install-recommends
RUN apt-get install git -y --no-install-recommends

# Install mcrcon
RUN git clone https://github.com/Tiiffi/mcrcon.git
WORKDIR /tmp/mcrcon
RUN make
RUN make install
RUN cp mcrcon /usr/local/bin
RUN chmod +x /usr/local/bin/mcrcon
WORKDIR /tmp

# Initialize the server directory
RUN mkdir -p /usr/games/minecraft/server
RUN mkdir -p /usr/games/minecraft/server/world

# Make the world/ directory a volume so it can be restored when creating a new container
VOLUME /usr/games/minecraft/server/world

# Download the server
RUN wget -O installer.jar "https://maven.neoforged.net/releases/net/neoforged/forge/${NEOFORGE_VERSION}/forge-${NEOFORGE_VERSION}-installer.jar"
RUN java -jar installer.jar --installServer
RUN rm installer.jar
RUN mv * /usr/games/minecraft/server

# Download mods and configs
RUN wget -O modpack.zip "https://github.com/iwo-strzebonski/WizardTowerNeo-Server/releases/download/v${MODPACK_VERSION}/WizardTowerNeo-${MODPACK_VERSION}-SERVER.zip"
RUN unzip modpack.zip -d /usr/games/minecraft/server
RUN rm modpack.zip

# Configure the server
WORKDIR /usr/games/minecraft/server

RUN chmod +x ./run.sh
RUN ./run.sh

RUN sed -i "s/eula=false/eula=${EULA}/" eula.txt

RUN sed -i "s/# -Xmx4G/-Xmx4G/" user_jvm_args.txt

RUN echo "enable-command-block=true" >> server.properties
RUN echo "enable-rcon=true" >> server.properties
RUN echo "rcon.port=25575" >> server.properties
RUN echo "rcon.password=password" >> server.properties
RUN echo "view-distance=12" >> server.properties
RUN echo "difficulty=hard" >> server.properties
RUN echo "motd=Pondering the orb..." >> server.properties

RUN sed -i "s/accept-download: false/accept-download: ${EULA}/" ./config/bluemap/core.conf

# Create the rcon alias
RUN echo -e "#!/bin/bash\nmcrcon -H localhost -P 25575 -p password '$@'" > /usr/bin/rcon && chmod +x /usr/bin/rcon

# Clean up the system
RUN apt-get clean
RUN rm -rf /var/lib/apt/lists/*
RUN rm -rf /var/cache/*
RUN rm -rf /tmp/*

# Expose ports
EXPOSE 25565
EXPOSE 25575
EXPOSE 8100

# Start the server
ENTRYPOINT [ "./run.sh" ] 
