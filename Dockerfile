# Use Ubuntu 22.04 as the base image
FROM ubuntu:22.04

ARG SDK_URL=https://drive.google.com/file/d/1bQrszU23AyFWGS9-mnIetGobsmtvg13W/view?usp=drive_link
# Set environment variables to avoid interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive
# Configure ccache
ENV CCACHE_DIR=/home/build/.ccache
ENV CCACHE_MAXSIZE=2G
ENV CCACHE_SLOPPINESS=pch_defines,time_macros
ENV CCACHE_COMPRESS=true
ENV CCACHE_COMPRESSLEVEL=6
ENV CCACHE_MAXFILES=1000000
ENV PATH="/usr/lib/ccache:$PATH"

# Set conservative parallel build options to avoid resource exhaustion
# Use half of available cores to leave plenty of headroom for nested builds
ENV MAKEFLAGS="-j$(($(nproc) / 2))"
ENV NINJA_STATUS="[%f/%t] "


# Update and install required dependencies
RUN apt-get update && apt-get install -y git ssh make gcc libssl-dev \
    liblz4-tool expect expect-dev g++ patchelf chrpath gawk texinfo chrpath \
    diffstat binfmt-support qemu-user-static live-build bison flex fakeroot \
    cmake gcc-multilib g++-multilib unzip device-tree-compiler ncurses-dev \
    libgucharmap-2-90-dev bzip2 expat gpgv2 cpp-aarch64-linux-gnu libgmp-dev \
    libmpc-dev bc python-is-python3 python2 rsync curl file ccache util-linux \
    bsdmainutils python3-pip \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Configure the required python2 environment
RUN update-alternatives --install /usr/bin/python python /usr/bin/python2 1 \
    && update-alternatives --install /usr/bin/python python /usr/bin/python3 2 \
    && update-alternatives --set python /usr/bin/python2

RUN pip3 install gdown

RUN mkdir -p /opt/Lyra-SDK

# Latest Luckfox Lyra SDK:
#
RUN gdown --fuzzy $SDK_URL -O /opt/Lyra-SDK/Luckfox_Lyra_SDK.tar.gz

RUN tar -xzf /opt/Lyra-SDK/Luckfox_Lyra_SDK.tar.gz -C /opt/Lyra-SDK && rm /opt/Lyra-SDK/Luckfox_Lyra_SDK.tar.gz

# Copy the entrypoint script
COPY ./docker/entrypoint.sh /opt/Lyra-SDK/entrypoint.sh

# Create directories for the build process
# Don't set specific ownership since we'll run as the host user
RUN mkdir -p /opt/Lyra-SDK/output && \
    chmod 755 /opt/Lyra-SDK/entrypoint.sh

# Don't specify a USER - we'll use --user at runtime

# Copy and unpack the Luckfox Lyra SDK
WORKDIR /opt/Lyra-SDK

# Set up the environment for the SDK
RUN ./.repo/repo/repo sync -l

COPY ./base /opt/Lyra-SDK/customizations/base
COPY ./scripts/prepare.sh /opt/Lyra-SDK/customizations/prepare.sh

RUN cd customizations \
    && ./prepare.sh \
    && cd ..

# Set the build script as the entrypoint
ENTRYPOINT ["/opt/Lyra-SDK/entrypoint.sh"]