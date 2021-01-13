FROM ubuntu:latest
MAINTAINER "Chris Miller" <c.a.miller@wustl.edu>

ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update -y && \
    apt-get install \
    build-essential \
    bzip2 \
    cmake \
    default-jre \
    g++ \
    git \
    libbz2-dev \
    liblzma-dev \
    libncurses5 \
    libtbb2 \
    libtbb-dev \
    make \
    ncurses-dev \
    wget \
    xz-utils \
    zlib1g-dev -y
    
##################
# Biscuit 0.3.16 #
##################
RUN mkdir /opt/biscuit_binary && cd /opt/biscuit_binary && \
    wget https://github.com/huishenlab/biscuit/releases/download/v0.3.16.20200420/biscuit_0_3_16_linux_amd64 && \
    chmod +x /opt/biscuit_binary/biscuit_0_3_16_linux_amd64 && \
    ln -s /opt/biscuit_binary/biscuit_0_3_16_linux_amd64 biscuit && \
    ln -s /opt/biscuit_binary/biscuit_0_3_16_linux_amd64 /usr/bin/biscuit

###############
# Flexbar 3.5 #
###############

RUN mkdir -p /opt/flexbar/tmp \
    && cd /opt/flexbar/tmp \
    && wget https://github.com/seqan/flexbar/archive/v3.5.0.tar.gz \
    && wget https://github.com/seqan/seqan/releases/download/seqan-v2.4.0/seqan-library-2.4.0.tar.xz \
    && tar xzf v3.5.0.tar.gz \
    && tar xJf seqan-library-2.4.0.tar.xz \
    && mv seqan-library-2.4.0/include flexbar-3.5.0 \
    && cd flexbar-3.5.0 \
    && cmake . \
    && make \
    && cp flexbar /opt/flexbar/ \
    && cd / \
    && rm -rf /opt/flexbar/tmp


##############
#HTSlib 1.3.2#
##############
ENV HTSLIB_INSTALL_DIR=/opt/htslib
WORKDIR /tmp
RUN wget https://github.com/samtools/htslib/releases/download/1.3.2/htslib-1.3.2.tar.bz2 && \
    tar --bzip2 -xvf htslib-1.3.2.tar.bz2 && \
    cd /tmp/htslib-1.3.2 && \
    ./configure  --enable-plugins --prefix=$HTSLIB_INSTALL_DIR && \
    make && \
    make install && \
    cp $HTSLIB_INSTALL_DIR/lib/libhts.so* /usr/lib/

#################
# Picard        #
#################

RUN mkdir /opt/picard-2.18.1/ \
    && cd /tmp/ \
    && wget --no-check-certificate https://github.com/broadinstitute/picard/releases/download/2.18.1/picard.jar \
    && mv picard.jar /opt/picard-2.18.1/ \
    && ln -s /opt/picard-2.18.1 /opt/picard \
    && ln -s /opt/picard-2.18.1 /usr/picard

#################
#Sambamba v0.6.4#
#################

RUN mkdir /opt/sambamba/ \
    && wget https://github.com/lomereiter/sambamba/releases/download/v0.6.4/sambamba_v0.6.4_linux.tar.bz2 \
    && tar --extract --bzip2 --directory=/opt/sambamba --file=sambamba_v0.6.4_linux.tar.bz2 \
    && ln -s /opt/sambamba/sambamba_v0.6.4 /usr/bin/sambamba
   ADD sambamba_merge /usr/bin/
   RUN chmod +x /usr/bin/sambamba_merge


################
#Samtools 1.3.1#
################
   ENV SAMTOOLS_INSTALL_DIR=/opt/samtools
   RUN cd /tmp && wget https://github.com/samtools/samtools/releases/download/1.3.1/samtools-1.3.1.tar.bz2 && \
       tar --bzip2 -xf samtools-1.3.1.tar.bz2 && cd /tmp/samtools-1.3.1 && \
       ./configure --with-htslib=$HTSLIB_INSTALL_DIR --prefix=$SAMTOOLS_INSTALL_DIR && \
       make && \
       make install && \
       cd / && rm -rf /tmp/samtools-1.3.1 && ln -s /opt/samtools/bin/samtools /usr/bin/samtools

##########
#Bedtools#
##########

RUN mkdir /opt/bedtools && cd /opt/bedtools && wget https://github.com/arq5x/bedtools2/releases/download/v2.29.2/bedtools.static.binary && \
    chmod +x /opt/bedtools/bedtools.static.binary && \
    ln -s /opt/bedtools/bedtools.static.binary /usr/bin/bedtools

# ARG PACKAGE_VERSION=2.27.1
# ARG BUILD_PACKAGES="git openssl python build-essential zlib1g-dev"
# ARG DEBIAN_FRONTEND=noninteractiveq
# RUN apt-get update && \
#     apt-get install --yes \
#               $BUILD_PACKAGES && \
#     cd /tmp && \
#     git clone https://github.com/arq5x/bedtools2.git && \
#     cd bedtools2 && \
#     git checkout v$PACKAGE_VERSION && \
#     make && \
#     mv bin/* /usr/local/bin && \
#     cd / && \
#     rm -rf /tmp/* && \
#     apt remove --purge --yes \
#               $BUILD_PACKAGES && \
#     apt autoremove --purge --yes && \
#     apt clean && \
#     rm -rf /var/lib/apt/lists/*

####################
#Biscuit QC scripts#
####################
RUN cd /opt && \
    git clone https://github.com/zwdzwd/biscuit.git
## Adding QC_scripts
ADD Bisulfite_QC_bisulfiteconversion.sh /opt/biscuit/scripts
ADD Bisulfite_QC_Coveragestats.sh /opt/biscuit/scripts
ADD Bisulfite_QC_CpGretentiondistribution.sh /opt/biscuit/scripts
ADD Bisulfite_QC_mappingsummary.sh /opt/biscuit/scripts

RUN apt-get update -y && \
    apt-get install 