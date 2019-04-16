FROM zhouwanding/biscuit_v0.3.8
MAINTAINER "Chris Miller" <c.a.miller@wustl.edu>

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

   WORKDIR /tmp
   RUN wget https://github.com/samtools/samtools/releases/download/1.3.1/samtools-1.3.1.tar.bz2 && \
       tar --bzip2 -xf samtools-1.3.1.tar.bz2

   WORKDIR /tmp/samtools-1.3.1
   RUN ./configure --with-htslib=$HTSLIB_INSTALL_DIR --prefix=$SAMTOOLS_INSTALL_DIR && \
       make && \
       make install

   WORKDIR /
   RUN rm -rf /tmp/samtools-1.3.1





##########
#Bedtools#
##########

ARG PACKAGE_VERSION=2.27.1
ARG BUILD_PACKAGES="git openssl python build-essential zlib1g-dev"
ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update && \
    apt-get install --yes \
              $BUILD_PACKAGES && \
    cd /tmp && \
    git clone https://github.com/arq5x/bedtools2.git && \
    cd bedtools2 && \
    git checkout v$PACKAGE_VERSION && \
    make && \
    mv bin/* /usr/local/bin && \
    cd / && \
    rm -rf /tmp/* && \
    apt remove --purge --yes \
              $BUILD_PACKAGES && \
    apt autoremove --purge --yes && \
    apt clean && \
    rm -rf /var/lib/apt/lists/*
