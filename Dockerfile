# Use Ubuntu 22.04 as the base image
FROM ubuntu:22.04 as unpacker

RUN apt-get update && apt-get install -y \
    curl \
    git \
    python-is-python3 \
    python2 \
    tar \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

RUN update-alternatives --install /usr/bin/python python /usr/bin/python2 1 \
    && update-alternatives --install /usr/bin/python python /usr/bin/python3 2 \
    && update-alternatives --set python /usr/bin/python2

# Latest Luckfox Lyra SDK:
# Remove .repo, rtos, and .git directories to reduce image size.
# All together this reduces the size by around 7 GB.
RUN mkdir -p /opt/Lyra-SDK
COPY Luckfox_Lyra_SDK.tar.gz /opt/Lyra-SDK/Luckfox_Lyra_SDK.tar.gz
RUN tar -xzf /opt/Lyra-SDK/Luckfox_Lyra_SDK.tar.gz -C /opt/Lyra-SDK
RUN rm /opt/Lyra-SDK/Luckfox_Lyra_SDK.tar.gz
RUN mkdir -p /opt/Lyra-SDK/output /opt/Lyra-SDK/buildroot/output
WORKDIR /opt/Lyra-SDK
RUN ./.repo/repo/repo sync -l
RUN rm -rf .repo && \
    find . -type d -name ".git" -exec rm -rf {} +

FROM ubuntu:22.04 as builder

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
RUN apt-get update && apt-get install -y \
    autoconf \
    automake \
    autotools-dev \
    bc \
    binfmt-support \
    bison \
    bsdmainutils \
    bzip2 \
    ccache \
    chrpath \
    cmake \
    cpp-aarch64-linux-gnu \
    cpanminus \
    curl \
    device-tree-compiler \
    diffstat \
    expat \
    expect \
    expect-dev \
    fakeroot \
    file \
    flex \
    g++ \
    g++-multilib \
    gawk \
    gcc \
    gcc-multilib \
    git \
    gpgv2 \
    libgmp-dev \
    libgucharmap-2-90-dev \
    liblz4-tool \
    libmpc-dev \
    libperl-dev \
    libssl-dev \
    libtool \
    live-build \
    make \
    ncurses-dev \
    patchelf \
    perl \
    pkg-config \
    python-is-python3 \
    python2 \
    qemu-user-static \
    rsync \
    ssh \
    texinfo \
    unzip \
    util-linux \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Configure the required python2 environment
RUN update-alternatives --install /usr/bin/python python /usr/bin/python2 1 \
    && update-alternatives --install /usr/bin/python python /usr/bin/python3 2 \
    && update-alternatives --set python /usr/bin/python2

COPY --from=unpacker /opt/Lyra-SDK /opt/Lyra-SDK
COPY ./base /opt/Lyra-SDK/customizations/base
COPY ./docker/prepare.sh /opt/Lyra-SDK/customizations/prepare.sh
COPY ./docker/entrypoint.sh /opt/Lyra-SDK/entrypoint.sh

RUN cd /opt/Lyra-SDK/customizations && \
    ./prepare.sh

WORKDIR /opt/Lyra-SDK

# Set the entrypoint
ENTRYPOINT ["/opt/Lyra-SDK/entrypoint.sh"]