# Use Ubuntu 22.04 as the base image
FROM ubuntu:22.04 as unpacker

# Set environment variables to avoid interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive
# Configure ccache for root user
ENV CCACHE_DIR=/root/.ccache
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
    python3-pip \
    qemu-user-static \
    rsync \
    ssh \
    tar \
    texinfo \
    unzip \
    util-linux \
    vim \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Configure the required python2 environment
RUN update-alternatives --install /usr/bin/python python /usr/bin/python2 1 \
    && update-alternatives --install /usr/bin/python python /usr/bin/python3 2 \
    && update-alternatives --set python /usr/bin/python2

# Install gdown for downloading the SDK from Google Drive
RUN pip3 install gdown

RUN mkdir -p /opt/Lyra-SDK

COPY ./docker/entrypoint.sh /entrypoint.sh

WORKDIR /opt/Lyra-SDK

# Set the entrypoint
ENTRYPOINT ["/entrypoint.sh"]