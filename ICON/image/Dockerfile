FROM nvidia/cuda:10.1-devel-ubuntu16.04

RUN useradd -ms /bin/bash cscs

#ENV DEBIAN_FRONTEND=noninteractive

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
    libcurl4-openssl-dev \
    libxml2-dev \
    python2.7 \
    python-pip --yes --no-install-recommends && \
    apt-get clean

RUN pip install --upgrade pip setuptools

WORKDIR /home/cscs

USER cscs

RUN pip install --user easybuild

RUN git clone https://github.com/lucamar/production.git && \
    cd production && \
    git checkout tsa76

ENV PATH=$PATH:/home/cscs/.local/bin \
    EASYBUILD_MODULES_TOOL=EnvironmentModulesC \
    #EASYBUILD_MODULES_TOOL=EnvironmentModules \
    EASYBUILD_MODULE_SYNTAX=Tcl \
    EASYBUILD_ROBOT_PATHS=/home/cscs/production/easybuild/easyconfigs:/home/cscs/.local/easybuild/easyconfigs

#RUN eb binutils-2.30-GCCcore-7.3.0.eb -r

RUN mkdir -p /home/cscs/.local/easybuild/sources/PGI
COPY pgilinux-2019-1910-x86-64.tar.gz /home/cscs/.local/easybuild/sources/PGI/
COPY PGI-19.10-GCC-7.3.0-2.30.eb /home/cscs/production/easybuild/easyconfigs/p/PGI/
RUN eb PGI-19.10-GCC-7.3.0-2.30.eb -r
    # eb numactl-2.0.11-GCCcore-7.3.0.eb -r && \

# # # COPY UCX-1.5.2-GCCcore-7.3.0-cuda-9.1.eb /home/cscs/.local/easybuild/easyconfigs/u/UCX/
# # # RUN eb UCX-1.5.2-GCCcore-7.3.0-cuda-9.1.eb -r
# # 
COPY Szip-2.1.1-PGI-19.10-GCC-7.3.0-2.30.eb /home/cscs/production/easybuild/easyconfigs/s/Szip/
COPY OpenMPI-4.0.1-PGI-19.10-GCC-7.3.0-2.30.eb /home/cscs/production/easybuild/easyconfigs/o/OpenMPI/
#RUN eb OpenMPI-4.0.1-PGI-19.10-GCC-7.3.0-2.30.eb

COPY HDF5-1.10.5-PGI-19.10-GCC-7.3.0-2.30.eb /home/cscs/production/easybuild/easyconfigs/H/HDF5/
RUN eb HDF5-1.10.5-PGI-19.10-GCC-7.3.0-2.30.eb -r

#COPY --chown=cscs osu /home/cscs/osu/
#RUN /bin/bash -c ". /usr/share/modules/init/bash && module user .local/easybuild/modules/all && module load OpenMPI/4.0.1-PGI-19.4-GCC-7.3.0-2.30 && cd osu && make -f Makefile_p2p CC=mpicc"

COPY netCDF-4.6.1-PGI-19.10-GCC-7.3.0-2.30.eb /home/cscs/production/easybuild/easyconfigs/n/netCDF/

RUN eb CMake-3.14.1.eb -r

COPY netCDF-Fortran-4.4.4-PGI-19.10-GCC-7.3.0-2.30.eb /home/cscs/production/easybuild/easyconfigs/n/netCDF-Fortran/
RUN eb netCDF-Fortran-4.4.4-PGI-19.10-GCC-7.3.0-2.30.eb -r

COPY MPICH-3.1.4-PGI-19.10-GCC-7.3.0-2.30.eb /home/cscs/production/easybuild/easyconfigs/m/MPICH/

RUN eb MPICH-3.1.4-PGI-19.10-GCC-7.3.0-2.30.eb -r

RUN ln -s /usr/lib/x86_64-linux-gnu/libxml2.a ~/.local/lib/ && \
    mkdir ~/.local/include && \
    ln -s /usr/include/libxml2 ~/.local/include/

COPY JasPer-2.0.14-PGI-19.10-GCC-7.3.0-2.30.eb /home/cscs/production/easybuild/easyconfigs/j/JasPer
RUN eb JasPer-2.0.14-PGI-19.10-GCC-7.3.0-2.30.eb -r

COPY ecCodes-2.13.0-PGI-19.10-GCC-7.3.0-2.30.eb /home/cscs/production/easybuild/easyconfigs/c/ecCodes/
RUN eb ecCodes-2.13.0-PGI-19.10-GCC-7.3.0-2.30.eb

ENV ICON_DOCKER=1

RUN echo  '. /usr/share/modules/init/bash' >> /home/cscs/.bashrc && \
    echo  'module use /home/cscs/.local/easybuild/modules/all' >> /home/cscs/.bashrc
