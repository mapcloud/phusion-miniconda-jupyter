# -*- mode: ruby -*-
# vi: set ft=ruby :

FROM jedisct1/phusion-baseimage-latest:16.04

LABEL maintainer "Aquabiota Solutions AB <mapcloud@aquabiota.se>"

# Use baseimage-docker's init system.
CMD ["/sbin/my_init"]

###############################################
# ENV LANG=C.UTF-8 LC_ALL=C.UTF-8

# following some ideas from https://github.com/jupyter/docker-stacks/blob/master/base-notebook/Dockerfile

#ENV DEBIAN_FRONTEND noninteractive
RUN apt-get update --fix-missing && \
    apt-get -yq dist-upgrade && \
    apt-get install -yq --no-install-recommends \
      wget \
      bzip2 \
      ca-certificates \
      python3-pip \
      software-properties-common \
      git \
      curl \
      sudo \
      locales
    # && \
    #apt-get clean && \
    #rm -rf /var/lib/apt/lists/*

RUN echo "en_US.UTF-8 UTF-8" > /etc/locale.gen && \
    locale-gen

# Configure environment

ENV CONDA_DIR /opt/conda
ENV PATH $CONDA_DIR/bin:$PATH
ENV SHELL /bin/bash
ENV NOTEBOOK_DIR /opt/notebooks
ENV LC_ALL en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US.UTF-8
ENV JUPYTER_CONFIG_DIR /root/.ipython/profile_default/


# relax the permissions on that directory and those files by making them world-readable
# See security in https://github.com/phusion/baseimage-docker
RUN chmod 755 /etc/container_environment && \
    chmod 644 /etc/container_environment.sh /etc/container_environment.json
#
RUN mkdir -p $CONDA_DIR && \
    mkdir -p $JUPYTER_CONFIG_DIR

# Install conda as jovyan
RUN cd /tmp && \
    mkdir -p $CONDA_DIR && \
    wget --quiet https://repo.continuum.io/miniconda/Miniconda3-4.2.12-Linux-x86_64.sh && \
    echo "c59b3dd3cad550ac7596e0d599b91e75d88826db132e4146030ef471bb434e9a *Miniconda3-4.2.12-Linux-x86_64.sh" | sha256sum -c - && \
    /bin/bash Miniconda3-4.2.12-Linux-x86_64.sh -f -b -p $CONDA_DIR && \
    rm Miniconda3-4.2.12-Linux-x86_64.sh && \
    $CONDA_DIR/bin/conda config --system --add channels conda-forge && \
    $CONDA_DIR/bin/conda config --system --set auto_update_conda false && \
    conda clean -tipsy

RUN conda create --name amasing && source activate amasing
# Install Jupyter Notebook and Hub and other requirements --quiet
COPY conda-requirements.txt /tmp/
RUN conda install -n amasing -y  --file /tmp/conda-requirements.txt

# Installing pip requirements not available through conda
COPY pip-requirements.txt /tmp/
RUN pip install --requirement /tmp/pip-requirements.txt

RUN ipython profile create && echo $(ipython locate)
COPY ipython_config.py $(ipython locate)/profile_default

# Make sure that notebooks is the current WORKDIR
WORKDIR $NOTEBOOK_DIR

EXPOSE 8888
VOLUME $NOTEBOOK_DIR

RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
# Clean up APT when done.

# # Add local files as late as possible to avoid cache busting
## Adding jupyter daemon
RUN mkdir /etc/service/jupyter
ADD jupyter.sh /etc/service/jupyter/run


# added HEALTHCHECK
# HEALTHCHECK CMD curl --fail http://localhost:8888/ || exit 1
