FROM debian:12

#-- Set `apt` as non-interactive
ENV DEBIAN_FRONTEND=noninteractive

#-- Install core dependencies for setting up the server
RUN apt update && \
    apt install --assume-yes --no-install-recommends \
    #-- For remotely accessing the server
    openssh-server \
    #-- For remotely accessing the server via SFTP
    openssh-sftp-server \
    #-- Used to download the mod pack
    wget \
    #-- Used to extract the mod pack
    7zip \
    #-- Needed for up to date CA certificates
    ca-certificates \
    #-- Used to install the Debian repository for Java
    apt-transport-https gnupg && \
    #-- Clean up the package cache
    apt clean && \
    rm -rf /var/lib/apt/lists/*

#-- Add the Debian repository for Java
RUN mkdir -p /etc/apt/keyrings/ && \
    wget -O packages.adoptium.net.key https://packages.adoptium.net/artifactory/api/gpg/key/public && \
    gpg --no-default-keyring --keyring temp-keyring.gpg --import packages.adoptium.net.key && \
    gpg --no-default-keyring --keyring temp-keyring.gpg --export --output packages.adoptium.net.gpg && \
    mv packages.adoptium.net.gpg /etc/apt/keyrings/ && \
    echo "deb [signed-by=/etc/apt/keyrings/packages.adoptium.net.gpg] https://packages.adoptium.net/artifactory/deb $(awk -F= '/^VERSION_CODENAME/{print$2}' /etc/os-release) main" | tee /etc/apt/sources.list.d/adoptium.list && \
    rm packages.adoptium.net.key /root/.gnupg/temp-keyring.gpg

#-- Install Java
RUN apt update && \
    apt install --assume-yes --no-install-recommends \
    temurin-8-jre && \
    #-- Clean up the package cache
    apt clean && \
    rm -rf /var/lib/apt/lists/*

#-- Set up our user and user group
RUN groupadd -g 1000 minecraft && \
    useradd -u 1000 -g minecraft -m minecraft

#-- Switch to our user
USER minecraft

#-- Set the working directory
WORKDIR /home/minecraft

#-- Download the mod pack
RUN wget -O modpack.zip https://mediafilez.forgecdn.net/files/5842/797/Meatballcraft-beta-0.16.5-hotfix3.zip

#-- Extract the mod pack and delete the downloaded zip
RUN 7zz x modpack.zip && \
    mv Meatballcraft-Server-beta-0.16.5-hotfix3/* . && \
    rm modpack.zip

#-- Remove Journey Map
RUN rm mods/journeymap*

#-- Download our custom mods
RUN wget --directory-prefix=mods https://mediafilez.forgecdn.net/files/2685/984/BetterAdvancements-1.12.2-0.1.0.77.jar && \
    wget --directory-prefix=mods https://mediafilez.forgecdn.net/files/2880/613/comforts-1.12.2-1.4.1.3.jar && \
    wget --directory-prefix=mods https://mediafilez.forgecdn.net/files/2689/502/EnchantmentDescriptions-1.12.2-1.1.15.jar && \
    wget --directory-prefix=mods https://mediafilez.forgecdn.net/files/3524/685/JustEnoughCalculation-1.12.2-3.2.7.jar && \
    wget --directory-prefix=mods https://mediafilez.forgecdn.net/files/5187/152/serializationisbad-1.5.2.jar && \
    wget --directory-prefix=mods https://mediafilez.forgecdn.net/files/5828/524/visualores-0.2.6.jar && \
    wget --directory-prefix=mods https://mediafilez.forgecdn.net/files/5794/929/voicechat-forge-1.12.2-2.5.24.jar && \
    wget --directory-prefix=mods https://mediafilez.forgecdn.net/files/5772/983/Xaeros_Minimap_24.5.0_Forge_1.12.jar && \
    wget --directory-prefix=mods https://mediafilez.forgecdn.net/files/5658/210/XaerosWorldMap_1.39.0_Forge_1.12.jar

#-- Ensure `ServerStart.sh` is executable
RUN chmod u+x ServerStart.sh

#-- We agree to Mojang's EULA
RUN echo "eula=true" > eula.txt

#-- Copy over our overrides
COPY --chown=minecraft:minecraft overrides ./overrides

#-- Merge our overrides into the mod pack
RUN cp -r overrides/* . && \
    rm -r overrides

#-- Setup the volume for the server world data
VOLUME /home/minecraft/world

#-- Expose the port for the Minecraft server
EXPOSE 25565

#-- Set the entrypoint for the container
ENTRYPOINT [ "/home/minecraft/ServerStart.sh" ]
