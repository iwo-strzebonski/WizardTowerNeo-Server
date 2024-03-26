FROM ubuntu:24.04

WORKDIR /usr/games/minecraft

# Update the system
RUN apt-get update -y
RUN apt-get upgrade -y

# Install the required packages
RUN apt-get install openjdk-17-jdk openjdk-17-jre -y --no-install-recommends

# Clean up the system
RUN apt-get clean
RUN rm -rf /var/lib/apt/lists/*

# Initialize the server
COPY /mc-server/server ./server

WORKDIR /usr/games/minecraft/server

RUN chmod +x ./run.sh
RUN ./run.sh
RUN sed -i "s/eula=false/eula=true/" ./eula.txt
RUN sed -i "s/# -Xmx4G/-Xmx4G/" ./user_jvm_args.txt

# Expose ports
EXPOSE 25565
EXPOSE 8100

# Start the server
ENTRYPOINT [ "./run.sh" ] 
