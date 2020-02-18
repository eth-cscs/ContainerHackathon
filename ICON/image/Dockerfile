FROM nvidia/cuda:10.1-devel-ubuntu16.04 AS stage1

RUN useradd -ms /bin/bash cscs

# It might be necessary for newer versions of 
# ubuntu to add the following line in order
# to avoid interactive questions from apt-get
# ENV DEBIAN_FRONTEND=noninteractive

# * libxml2-dev is needed by icon
# * libcurl4-openssl-dev is needed by ./configure
# * bison, flex and default-jdk are needed by claw
# * the rest are utilities to use when running the 
#   container interactively.
RUN apt-get update && \
    apt-get install \
    wget \
    ssh \
    vim \
    ksh \
    less \
    environment-modules \
    git \
    rsync \
    bison \
    flex \
    default-jdk \
    gfortran \
    libcurl4-openssl-dev \
    libxml2-dev \
    python3.5 \
    ant \
    python3-pip --yes --no-install-recommends && \
    apt-get clean

RUN pip3 install --upgrade pip setuptools

WORKDIR /home/cscs

# Switch to the user cscs
# It's possible to switch back and forth to root doing
# `USER root` and `USER cscs`.
USER cscs

# `apt-get install` puts libs and includes on different paths.
# Here we put libxml2's lib and include on the same place,
# otherwise ./configure can't find it.
RUN mkdir -p ~/.local/include ~/.local/lib && \
    ln -s /usr/lib/x86_64-linux-gnu/libxml2.a ~/.local/lib/ && \    
    ln -s /usr/include/libxml2 ~/.local/include/

# Install and setup EasyBuild
RUN pip3 install --user easybuild==4.1.1
RUN git clone https://github.com/lucamar/production.git && \
    cd production && \
    git checkout tsa76
ENV PATH=$PATH:/home/cscs/.local/bin \
    EASYBUILD_MODULES_TOOL=EnvironmentModulesC \
    EASYBUILD_MODULE_SYNTAX=Tcl \
    EASYBUILD_ROBOT_PATHS=/home/cscs/production/easybuild/easyconfigs:/home/cscs/.local/easybuild/easyconfigs

# We have commented the following lines on the easyconfig for PGI:
# dependencies = [
#     ('GCCcore', gccver),
#     ('binutils', binutilsver, '', ('GCCcore', gccver)),
# ]
# Doing this we use the system compilers instead of installing them with EB.
# This is faster, but not clean since this restrict the GCC to
# whatever version is available through `apt-get install`.
#
# We copy and install the PGI compilers on the image.
RUN mkdir -p /home/cscs/.local/easybuild/sources/PGI
COPY pgilinux-2019-1910-x86-64.tar.gz /home/cscs/.local/easybuild/sources/PGI/
COPY PGI-19.10-GCC-7.3.0-2.30.eb /home/cscs/production/easybuild/easyconfigs/p/PGI/
RUN eb PGI-19.10-GCC-7.3.0-2.30.eb -r

# Install CMake. The easyconfig was already pulled with the production repository
RUN eb CMake-3.14.1.eb -r

# HDF5
COPY Szip-2.1.1-PGI-19.10-GCC-7.3.0-2.30.eb /home/cscs/production/easybuild/easyconfigs/s/Szip/
COPY HDF5-1.10.5-PGI-19.10-GCC-7.3.0-2.30.eb /home/cscs/production/easybuild/easyconfigs/H/HDF5/
RUN eb HDF5-1.10.5-PGI-19.10-GCC-7.3.0-2.30.eb -r

# netCDF and netCDF-Fortran
COPY netCDF-4.6.1-PGI-19.10-GCC-7.3.0-2.30.eb /home/cscs/production/easybuild/easyconfigs/n/netCDF/
COPY netCDF-Fortran-4.4.4-PGI-19.10-GCC-7.3.0-2.30.eb /home/cscs/production/easybuild/easyconfigs/n/netCDF-Fortran/
RUN eb netCDF-Fortran-4.4.4-PGI-19.10-GCC-7.3.0-2.30.eb -r

# MPICH
COPY MPICH-3.1.4-PGI-19.10-GCC-7.3.0-2.30.eb /home/cscs/production/easybuild/easyconfigs/m/MPICH/
RUN eb MPICH-3.1.4-PGI-19.10-GCC-7.3.0-2.30.eb -r

# ecCodes
COPY JasPer-2.0.14-PGI-19.10-GCC-7.3.0-2.30.eb /home/cscs/production/easybuild/easyconfigs/j/JasPer
RUN eb JasPer-2.0.14-PGI-19.10-GCC-7.3.0-2.30.eb -r
COPY ecCodes-2.13.0-PGI-19.10-GCC-7.3.0-2.30.eb /home/cscs/production/easybuild/easyconfigs/c/ecCodes/
RUN eb ecCodes-2.13.0-PGI-19.10-GCC-7.3.0-2.30.eb

# Install claw be hand while there's no easyconfig
# here we check out to the commit d60d413. That's the one we
# tested with durring the hackathon.
# now the maven repository is accessible only via https. Because
# of this we had to update ivy (which apparently doesn't
# support https) from 2.3.0 to 2.5.0.
RUN git clone https://github.com/claw-project/claw-compiler.git && \
    cd claw-compiler && \
    git submodule init && \
    git submodule update --remote && \
    git checkout d60d413 && \
    sed -i 's/2.3.0/2.5.0/g' cx2t/common-targets.xml && \
    mkdir build && \
    cd build && \
    . /usr/share/modules/init/sh && \
    module use /home/cscs/.local/easybuild/modules/all && \
    module load PGI MPICH CMake && \
    FC=mpif90 CC=mpicc CXX=mpicxx cmake -DCMAKE_INSTALL_PREFIX=/home/cscs/.local/claw -DOMNI_MPI_FC="MPI_FC=mpif90" -DOMNI_MPI_CC="MPI_CC=mpicc" .. && \
    make && \
    make install

# Set an env variable to indicate icon's build system that the
# that the building is happening within a container
ENV ICON_DOCKER=1

# Add module environment initialization to `.bashrc`.
# The initialization doens't work for some platforms. In that case
# the `.bashrc` needs to be sourced by hand before importing any modules.
RUN echo  '. /usr/share/modules/init/bash' >> /home/cscs/.bashrc && \
    echo  'module use /home/cscs/.local/easybuild/modules/all' >> /home/cscs/.bashrc



# Start a new image where we install the same apt-get stuff and copy the software
# that we have built.
# To have the same environment, we repeat all the steps up to the point where
# we start building software.
FROM nvidia/cuda:10.1-devel-ubuntu16.04

RUN useradd -ms /bin/bash cscs

RUN apt-get update && \
    apt-get install \
    wget \
    ssh \
    vim \
    ksh \
    less \
    environment-modules \
    git \
    rsync \
    bison \
    flex \
    default-jdk \
    gfortran \
    libcurl4-openssl-dev \
    libxml2-dev \
    python3.5 \
    ant \
    python3-pip --yes --no-install-recommends && \
    apt-get clean

RUN pip3 install --upgrade pip setuptools

WORKDIR /home/cscs

USER cscs

# `apt-get install` puts libs and includes on different paths.
# Here we put libxml2's lib and include on the same place,
# otherwise ./configure can't find it.
RUN mkdir -p ~/.local/include ~/.local/lib && \
    ln -s /usr/lib/x86_64-linux-gnu/libxml2.a ~/.local/lib/ && \    
    ln -s /usr/include/libxml2 ~/.local/include/

# create the folder where the files where we put the files we
# are going to copy
RUN mkdir -p /home/cscs/.local/easybuild/software \
             /home/cscs/.local/easybuild/modules \
             /home/cscs/.local/claw
#
# Copy only the files we need on the new image
COPY --from=stage1 /home/cscs/.local/easybuild/software /home/cscs/.local/easybuild/software
COPY --from=stage1 /home/cscs/.local/easybuild/modules /home/cscs/.local/easybuild/modules
COPY --from=stage1 /home/cscs/.local/claw /home/cscs/.local/claw
COPY --from=stage1 /home/cscs/.bashrc /home/cscs/
