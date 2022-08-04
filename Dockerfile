#################################################################
# Dockerfile
#
# Software:         HiC-Pro and dependencies
# Software Version: 3.1.0
# Website:          https://github.com/madetunj/HiC-Pro
# Provides:         All dependencies needed to run Abralab lab's HiC-Pro wrapper script
# Base Image:       ghcr.io/stjude/abralab/binf-base:1.1.0
# Build Cmd:        docker build --no-cache abralab/hicpro:v3.1.0 .
# Pull Cmd:         docker pull abralab/hicpro:v3.1.0
# Run Cmd:          docker run --rm -ti abralab/hicpro:v3.1.0
#################################################################

FROM ghcr.io/stjude/abralab/bedtools:v2.25.0 as frombed

FROM ghcr.io/stjude/abralab/binf-base:1.1.0
ENV LANG=C.UTF-8 LC_ALL=C.UTF-8

LABEL authors="Nicolas Servant" \
      description="Docker image containing all requirements for the HiC-Pro pipeline"

MAINTAINER Modupeore Adetunji "modupeore.adetunji@stjude.org"

## Install system tools
RUN apt-get update \
  && apt-get install -y bzip2 \
  gcc \
  g++ && apt-get clean


## Install miniconda.
RUN wget https://repo.continuum.io/miniconda/Miniconda3-py37_4.8.2-Linux-x86_64.sh -O ~/anaconda.sh
RUN bash ~/anaconda.sh -b -p /usr/local/anaconda
RUN rm ~/anaconda.sh
ENV PATH /usr/local/anaconda/bin:$PATH


## Install all dependencies using conda
COPY environment.yml /
RUN conda env create -f /environment.yml && conda clean -a
ENV PATH /usr/local/anaconda/envs/HiC-Pro_v3.1.0/bin:$PATH

## Install HiCPro
ENV H_VERSION 3.1.0
RUN cd /tmp && \
    echo "master.zip" | wget https://github.com/nservant/HiC-Pro/archive/refs/tags/v${H_VERSION}.zip && \
    unzip v${H_VERSION}.zip && \
    cd HiC-Pro-${H_VERSION}  && \ 
    sed -i "s/TORQUE/LSF/" config-install.txt && \
    make configure prefix=/ && \
    make install && \
    cd .. && \
    rm -fr HiC-Pro*

## Install JuicerTools
RUN cd /tmp && \
    wget https://s3.amazonaws.com/hicfiles.tc4ga.com/public/juicer/juicer_tools_1.22.01.jar && \
    mv juicer_tools_1.22.01.jar /usr/local/bin
    
## Get configuration file
RUN mkdir /data && cd /data && wget https://raw.githubusercontent.com/madetunj/HiC-Pro/master/config-hicpro.txt

## ADD DEPENDENCIES TO BASE IMAGE
COPY --from=frombed /opt/bedtools2/bin /usr/local/bin

RUN /HiC-Pro_3.1.0/bin/HiC-Pro -h
