FROM ubuntu

# Arguments required to work with the ECWMF proxy
# Delete the ARG and the following ENV if you don't need
ARG http_proxy
ARG ftp_proxy
ARG https_proxy
ARG no_proxy

# This is needed for internet access when running from ecwmf
#ENV http_proxy=$http_proxy \
#    ftp_proxy=$ftp_proxy \
#    https_proxy=$https_proxy \
#    no_proxy=$no_proxy

RUN apt-get update && \
    apt-get install -y build-essential && \
    apt-get install -y gcc gfortran && \
    apt-get install -y cmake perl wget && \
    apt-get install -y python libpython-dev python-pip && \
    pip install numpy && \
    apt-get install -y liblapack-dev libblas-dev vim && \
    apt-get install -y libnetcdf-dev libnetcdff-dev libnetcdf-c++4-dev && \
    apt-get install -y vim

RUN wget -q http://www.mpich.org/static/downloads/3.1.4/mpich-3.1.4.tar.gz \
    && tar xf mpich-3.1.4.tar.gz \
    && cd mpich-3.1.4 \
    && ./configure --enable-fortran --enable-fast=all,O3 --prefix=/usr \
    && make -j$(nproc) \
    && make install \
    && ldconfig \
    && cd .. \
    && rm -rf mpich-3.1.4 \
    && rm mpich-3.1.4.tar.gz

# download and install ecCodes library:
RUN wget -q https://confluence.ecmwf.int/download/attachments/45757960/eccodes-2.10.0-Source.tar.gz && \
    tar xf eccodes-2.10.0-Source.tar.gz

RUN mkdir -p bld && \
    cd bld && \
    cmake ../eccodes-2.10.0-Source \
      -DCMAKE_C_COMPILER=gcc \
      -DCMAKE_Fortran_COMPILER=gfortran \
      -DENABLE_NETCDF=ON \
      -DENABLE_JPG=OFF \
      -DENABLE_PNG=OFF \
      -DENABLE_PYTHON=ON \
      -DENABLE_FORTRAN=ON \
      -DBUILD_SHARED_LIBS=BOTH && \
    make -j$(nproc) && make check && make install && \
    cd ../ && rm eccodes-2.10.0-Source.tar.gz && rm -rf eccodes-2.10.0-Source bld

# Copy OpenIFS sources from tarball to image
ADD oifs43r3.tar.gz /

# # set OIFS env variables:
ENV OIFS_HOME=/oifs \
    OIFS_CYCLE=43r3 \
    OIFS_COMP=gnu   \
    OIFS_BUILD=opt  \
    OIFS_FFTW=disable \
    OIFS_XIOS=disable

ENV PATH=$OIFS_HOME/fcm/bin:$PATH \
    OIFS_GRIB_DIR="/usr/local"

ENV OIFS_GRIB_LIB="-L$OIFS_GRIB_DIR/lib -leccodes_f90 -leccodes"  \
    OIFS_GRIB_INCLUDE="-I$OIFS_GRIB_DIR/include"  \
    GRIB_SAMPLES_PATH=$OIFS_GRIB_DIR/share/eccodes/ifs_samples/grib1_mlgrib2

ENV OIFS_NETCDF_DIR=/usr \
    OIFS_NETCDF_INCLUDE="-I/usr/include" \
    OIFS_NETCDF_LIB="-L/usr/lib -L/usr/lib/x86_64-linux-gnu -lnetcdff -lnetcdf_c++4 -lnetcdf -Wl,-rpath,/usr/lib" \
    OIFS_EXTRA_LIB="$OIFS_EXTRA_LIB -ldl -lz -lrt"

RUN cd $OIFS_HOME/make && fcm make -v -j 4 -f oifs.cfg

# This is needed so that OpenIFS finds the dynamic libraries
ENV LD_LIBRARY_PATH=/usr/local/lib:$LD_LIBRARY_PATH

# Create a separate user to run as nonroot
RUN groupadd --gid 1000 oifs && \
    useradd --uid 1000 --gid oifs --shell /bin/bash --create-home oifs_user

USER oifs_user

WORKDIR /home/oifs_user
