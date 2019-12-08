#!/bin/bash
#################################################################################
# LFRic environment: Installs LFRic build dependencies. General prerequisites such
#       as compilers and Python are installed in 'lfric_deps.docker'. XIOS is
#       installed in 'install_xios_env.sh' script (to be run after this script).
#################################################################################
#
#################################################################################
# LFRic environment: Installs PSyclone and its prerequisites
################################################################################# 
#
# Ubuntu 18.04 comes with Python3 but no Python 2 installation. The LFRic trunk
# is still using Python2 so a version of Python 2 is installed to support
# dependency analyser and PSyclone
PSYCLONE_VERSION=1.7.0
# Installs Jinja2 (any version is fine), PSyclone prerequisites and PSyclone
# currently used by the LFRic trunk (any missing prerequisites will be installed as well)
pip install Jinja2 pyparsing six configparser psyclone==$PSYCLONE_VERSION
#
#################################################################################
# LFRic environment: Set installation and build directories with system
#       GCC compiler (version 7.4.0 for Ubuntu 18.04)
#################################################################################
#
# Set the compiler environment and create it if it does not exist
COMP_PACKAGE_DIR=$HOME/gnu_env
mkdir -p $COMP_PACKAGE_DIR
# Set path to installation directory and create it if it does not exist
export INSTALL_DIR=$COMP_PACKAGE_DIR/usr
mkdir -p $INSTALL_DIR
export PATH=$INSTALL_DIR/bin:$PATH
export LD_LIBRARY_PATH=$INSTALL_DIR/lib:$INSTALL_DIR/lib64:$LD_LIBRARY_PATH
export CPPFLAGS="-I$INSTALL_DIR/include"
export FFLAGS="-I$INSTALL_DIR/include"
export LDFLAGS="-L$INSTALL_DIR/lib"
# Set path to build directory and create it if it does not exist
export BUILD_DIR=$COMP_PACKAGE_DIR/build
mkdir -p $BUILD_DIR
# Set number of cores for building
NCORES=2
#
#################################################################################
# LFRic environment: Installs MPICH (version 3.1.4)
# Prerequisites: GCC (here system version 7.4.0)
# Note: Configured build with "--enable-shared" for building shared library
#################################################################################
#
# Set MPICH version
MPICH_VERSION=3.1.4
PACKAGE_NAME="mpich-"$MPICH_VERSION
# Download and unpack source
cd $BUILD_DIR
wget http://www.mpich.org/static/downloads/$MPICH_VERSION/$PACKAGE_NAME.tar.gz
tar -xzf $PACKAGE_NAME.tar.gz
# Make build directory if it does not exist
PACKAGE_DIR=$PACKAGE_NAME"_build"
mkdir -p $PACKAGE_DIR
cd $PACKAGE_DIR
# Configure and install
# Dynamic linking
FC=gfortran CC=gcc $BUILD_DIR/$PACKAGE_NAME/configure --prefix=$INSTALL_DIR --enable-fortran=all --enable-cxx --enable-threads=multiple --enable-shared --enable-romio
## Static linking
#FC=gfortran CC=gcc $BUILD_DIR/$PACKAGE_NAME/configure --prefix=$INSTALL_DIR --enable-fortran=all --enable-cxx --enable-threads=multiple --disable-shared --enable-romio
# Build
#make -j $NCORES
make
# Check: Disabled to save time
#make check
# Install
make install
#
#################################################################################
# LFRic environment: Installs YAXT (version 0.6.0)
# Prerequisites: MPICH (version 3.1.4)
# Note: Configured build with "--enable-shared" for building shared library
#################################################################################
#
# Set YAXT version
YAXT_VERSION=0.6.0
PACKAGE_NAME="yaxt-"$YAXT_VERSION
# Download and unpack source
cd $BUILD_DIR
wget https://www.dkrz.de/redmine/attachments/download/488/$PACKAGE_NAME.tar.gz
tar -xzf $PACKAGE_NAME.tar.gz 
# Make build directory if it does not exist
PACKAGE_DIR=$PACKAGE_NAME"_build"
mkdir -p $PACKAGE_DIR
cd $PACKAGE_DIR
# Configure and install
# Dynamic linking
$BUILD_DIR/$PACKAGE_NAME/configure --prefix=$INSTALL_DIR --with-idxtype=long CC=mpicc FC=mpif90 FPP="mpif90 -E" --enable-shared
## Static linking
#BUILD_DIR/$PACKAGE_NAME/configure --prefix=$INSTALL_DIR --with-idxtype=long CC=mpicc FC=mpif90 FPP="mpif90 -E" --disable-shared
# Build
make -j $NCORES
# Check: Tests pass when run from build directory, however they trip up from the
# installation directory, hence disabling them
#make check
# Install
make install
#
#################################################################################
# LFRic environment: Installs HDF5 (version 1.8.16)
# Prerequisites: GCC (here system 7.4.0) and MPICH (version 3.1.4)
# Note: Configured build with "--enable-shared" for building shared library
#################################################################################
#
# Set HDF5 version
HDF5_MAJOR_VERSION=1.8
HDF5_VERSION=$HDF5_MAJOR_VERSION.16
PACKAGE_NAME="hdf5-"$HDF5_VERSION
# Download and unpack source
cd $BUILD_DIR
wget http://www.hdfgroup.org/ftp/HDF5/prev-releases/hdf5-$HDF5_MAJOR_VERSION/$PACKAGE_NAME/src/$PACKAGE_NAME.tar.gz
tar -xzf $PACKAGE_NAME.tar.gz
# Make build directory if it does not exist
PACKAGE_DIR=$PACKAGE_NAME"_build"
mkdir -p $PACKAGE_DIR
cd $PACKAGE_DIR
# Configure and install
# Dynamic linking
CC=mpicc FC=mpif90 $BUILD_DIR/$PACKAGE_NAME/configure --prefix=$INSTALL_DIR --enable-shared --enable-fortran --enable-fortran2003 --enable-parallel
## Static linking
#CC=mpicc FC=mpif90 $BUILD_DIR/$PACKAGE_NAME/configure --prefix=$INSTALL_DIR --disable-shared --enable-static --enable-fortran --enable-fortran2003 --enable-parallel --enable-static-exec --with-szlib=no
# Build
make -j $NCORES
# Check: There may be "Testing t_cache" hang-ups during "make check" phase, so to prevent
# them either set MV2_ENABLE_AFFINITY flag to 0 or just disable checks altogether
#export MV2_ENABLE_AFFINITY=0
#make check
# Install
make install
#
#################################################################################
# LFRic environment: Installs NETCDF (version 4.3.3.1)
# Prerequisites: MPICH (version 3.1.4) and HDF5 (version 1.8.16)
# Note: Configured build with "--enable-shared" for building dynamic libraries
# (see https://www.unidata.ucar.edu/software/netcdf/docs/building_netcdf_fortran.html)
#################################################################################
#
# Set NETCDF version
NETCDF_VERSION=4.3.3.1
PACKAGE_NAME="netcdf-"$NETCDF_VERSION
# Download and unpack source
cd $BUILD_DIR
wget ftp://ftp.unidata.ucar.edu/pub/netcdf/$PACKAGE_NAME.tar.gz
tar -xzf $PACKAGE_NAME.tar.gz
# Make build directory if it does not exist
PACKAGE_DIR=$PACKAGE_NAME"_build"
mkdir -p $PACKAGE_DIR
cd $PACKAGE_DIR
# Configure and install (--disable-dap removes the error with "curl" library
# and the remote client is not needed anyway)
# Dynamic linking
CC=mpicc CXX=mpicxx FF=mpif90 FC=mpif90 $BUILD_DIR/$PACKAGE_NAME/configure --prefix=$INSTALL_DIR --enable-shared --disable-dap
## Static linking
#CC=mpicc CXX=mpicxx FF=mpif90 FC=mpif90 $BUILD_DIR/$PACKAGE_NAME/configure --prefix=$INSTALL_DIR --disable-shared --disable-dap
# Build
make -j $NCORES
# Check: Disabled to save time
#make check
# Install
make install
#
#################################################################################
# LFRic environment: Installs NETCDF Fortran binding (version 4.4.2)
# Prerequisites: MPICH (version 3.1.4), HDF5 (version 1.8.16) and
#                NETCDF (version 4.3.3.1)
# Note: Configured build with "--enable-shared" for building shared libraries
# (see https://www.unidata.ucar.edu/software/netcdf/docs/building_netcdf_fortran.html)
#################################################################################
#
# Set NETCDF Fortran binding version
NETCDF_FORTRAN_VERSION=4.4.2
PACKAGE_NAME="netcdf-fortran-"$NETCDF_FORTRAN_VERSION
# Download and unpack source
cd $BUILD_DIR
wget ftp://ftp.unidata.ucar.edu/pub/netcdf/$PACKAGE_NAME.tar.gz
tar -xzf $PACKAGE_NAME.tar.gz
# Make build directory if it does not exist
PACKAGE_DIR=$PACKAGE_NAME"_build"
mkdir -p $PACKAGE_DIR
cd $PACKAGE_DIR
# Configure and install
# Dynamic linking
CC=mpicc CXX=mpicxx FF=mpif90 FC=mpif90 $BUILD_DIR/$PACKAGE_NAME/configure --prefix=$INSTALL_DIR --enable-shared
## Static linking
## Additional flag to prevent static build errors
#LDFLAGS+=" -lnetcdf"
#CC=mpicc CXX=mpicxx FF=mpif90 FC=mpif90 $BUILD_DIR/$PACKAGE_NAME/configure --prefix=$INSTALL_DIR --disable-shared
# Build
make -j $NCORES
# Check: Disabled to save time
#make check
# Install
make install
#
#################################################################################
# LFRic environment: Installs NETCDF C++ bindings (version 4.2)
# Prerequisites: MPICH (version 3.1.4), HDF5 (version 1.8.16) and
#                NETCDF (version 4.3.3.1)
# Note: Configured build with "--enable-shared" for building shared libraries
# (see https://www.unidata.ucar.edu/software/netcdf/docs/building_netcdf_fortran.html)
#################################################################################
#
# Set NETCDF C++ binding version
NETCDF_CPP_VERSION=4.2
PACKAGE_NAME="netcdf-cxx-"$NETCDF_CPP_VERSION
# Download and unpack source
cd $BUILD_DIR
wget ftp://ftp.unidata.ucar.edu/pub/netcdf/$PACKAGE_NAME.tar.gz
tar -xzf $PACKAGE_NAME.tar.gz
# Make build directory if it does not exist
PACKAGE_DIR=$PACKAGE_NAME"_build"
mkdir -p $PACKAGE_DIR
cd $PACKAGE_DIR
# Configure and install
# Dynamic linking
CC=mpicc CXX=mpicxx FF=mpif90 FC=mpif90 $BUILD_DIR/$PACKAGE_NAME/configure --prefix=$INSTALL_DIR --enable-shared
## Static linking
## Note: make sure that the additional flag to prevent static build errors
## is set here or in the build of Fortran bindings above
##DFLAGS+=" -lnetcdf"
#CC=mpicc CXX=mpicxx FF=mpif90 FC=mpif90 $BUILD_DIR/$PACKAGE_NAME/configure --prefix=$INSTALL_DIR --disable-shared
# Build
make -j $NCORES
# Check: Disabled to save time
#make check
# Install
make install
#
#################################################################################
# LFRic environment: Installs PFUNIT (version 3.2.9)
# Prerequisites: MPICH (version 3.1.4) and CMAKE (here system version)
#################################################################################
#
# Set PFUNIT version
PFUNIT_VERSION=3.2.9
PACKAGE_DIR="pFUnit-"$PFUNIT_VERSION
# Download and unpack source
cd $BUILD_DIR
wget https://sourceforge.net/projects/pfunit/files/latest/download/$PACKAGE_DIR.tgz
tar -xzf $PACKAGE_DIR.tgz
cd $PACKAGE_DIR
# Set the required environment variables
export F90_VENDOR=GNU
export F90=gfortran
export MPIF90=mpif90
# Build
make -j $NCORES
# Check: Disabled to save time
#make tests
# Install
make install
