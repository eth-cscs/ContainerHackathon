#!/bin/bash
################################################################################
# LFRic environment: Install general prerequisites and tools
################################################################################ 
#
# Update
##sudo apt-get update
# Make and config tools
##sudo apt-get install -y make cmake automake libtool-bin pkg-config
# Install g++ if it is not present on the system (an existing g++ is required
# for boostrapping a GCC compiler source) - it will install the default 7.4.0
##sudo apt-get install -y g++ gcc gfortran
# Text editors, building documentation and source control
##sudo apt-get install -y doxygen git subversion
# Building HDF5 (m4, zlibg1*), NetCDF (curl) and XIOS (libcurl4*)
##sudo apt-get install -y m4 zlib1g-dev curl libcurl4 libcurl4-openssl-dev
#
################################################################################
# LFRic environment: Install Python2 and PSyclone
################################################################################ 
#
# Ubuntu 18.04 comes with Python3 but no Python 2 installation. The LFRic trunk
# is still using Python2 so a version of Python 2 is installed to support
# dependency analyser and PSyclone
PYTHON_VERSION=2.7
PSYCLONE_VERSION=1.7.0
# Install Python 2.7
###sudo apt-get install -y python python-pip
# Install Jinja2 (any version is fine), PSyclone requirements and PSyclone
# currently used by the LFRic trunk (any missing prerequisites will be installed as well)
pip install Jinja2 pyparsing six configparser PSyclone==$PSYCLONE_VERSION
#
################################################################################
# LFRic environment: Set installation and build directories with system
#                    gcc compiler
#################################################################################
# Set the compiler environment
COMP_PACKAGE_DIR=$HOME/gnu_env
mkdir -p $COMP_PACKAGE_DIR
# Set path to installation directory
export INSTALL_DIR=$COMP_PACKAGE_DIR/usr
mkdir -p $INSTALL_DIR
export PATH=$INSTALL_DIR/bin:$PATH
export LD_LIBRARY_PATH=$INSTALL_DIR/lib:$INSTALL_DIR/lib64:$LD_LIBRARY_PATH
export CPPFLAGS="-I$INSTALL_DIR/include"
export FFLAGS="-I$INSTALL_DIR/include"
export LDFLAGS="-L$INSTALL_DIR/lib"
# Set path to build directory
export BUILD_DIR=$COMP_PACKAGE_DIR/build
mkdir -p $BUILD_DIR
# Set number of cores for building
NCORES=2
#
################################################################################
# LFRic environment: Build MPICH (version 3.1.4)
# Prerequisites: GCC (here system version 7.4.0)
# Note: Configured build with "--enable-shared" for building shared library
################################################################################ 
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
###FC=gfortran CC=gcc $BUILD_DIR/$PACKAGE_NAME/configure --prefix=$INSTALL_DIR --enable-fortran=all --enable-cxx --enable-threads=multiple --disable-shared --enable-romio
FC=gfortran CC=gcc $BUILD_DIR/$PACKAGE_NAME/configure --prefix=$INSTALL_DIR --enable-fortran=all --enable-cxx --enable-threads=multiple --enable-shared --enable-romio
make -j $NCORES
###make check
make install
#
################################################################################
# LFRic environment: Build YAXT (version 0.6.0)
# Prerequisites: MPICH (version 3.1.4)
# Note: Configured build with "--enable-shared" for building shared library
################################################################################ 
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
###$BUILD_DIR/$PACKAGE_NAME/configure --prefix=$INSTALL_DIR --with-idxtype=long CC=mpicc FC=mpif90 FPP="mpif90 -E" --disable-shared
$BUILD_DIR/$PACKAGE_NAME/configure --prefix=$INSTALL_DIR --with-idxtype=long CC=mpicc FC=mpif90 FPP="mpif90 -E" --enable-shared
make -j $NCORES
# Tests pass when ran from build directory, however they trip up from the installation directory,
# hence disabling them
##make check
make install
#
################################################################################
# LFRic environment: Build HDF5 (version 1.8.16)
# Prerequisites: GCC (here system 7.4.0) and MPICH 3.1.4
# Note: Configured build with "--enable-shared" for building shared library
################################################################################ 
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
###CC=mpicc FC=mpif90 $BUILD_DIR/$PACKAGE_NAME/configure --prefix=$INSTALL_DIR --disable-shared --enable-static --enable-fortran --enable-fortran2003 --enable-parallel --enable-static-exec --with-szlib=no
CC=mpicc FC=mpif90 $BUILD_DIR/$PACKAGE_NAME/configure --prefix=$INSTALL_DIR --enable-shared --enable-fortran --enable-fortran2003 --enable-parallel
make -j $NCORES
#### Prevent "Testing t_cache" hangup during "make check" by setting - Disable checks!
###export MV2_ENABLE_AFFINITY=0
###make check
make install
#
################################################################################
# LFRic environment: Build NETCDF (version 4.3.3.1)
# Prerequisites: MPICH (version 3.1.4) and HDF5 (version 1.8.16)
# Note: Configured build with "--enable-shared" for building dynamic libraries
# (see https://www.unidata.ucar.edu/software/netcdf/docs/building_netcdf_fortran.html)
################################################################################ 
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
# and the remote client it is not needed anyway)
###CC=mpicc CXX=mpicxx FF=mpif90 FC=mpif90 $BUILD_DIR/$PACKAGE_NAME/configure --prefix=$INSTALL_DIR --disable-shared --disable-dap
CC=mpicc CXX=mpicxx FF=mpif90 FC=mpif90 $BUILD_DIR/$PACKAGE_NAME/configure --prefix=$INSTALL_DIR --enable-shared --disable-dap
make -j $NCORES
###make check
make install
#
################################################################################
# LFRic environment: Build NETCDF Fortran binding (version 4.4.2)
# Prerequisites: MPICH (version 3.1.4) and HDF5 (version 1.8.16)
# Note: Configured build with "--enable-shared" for building shared libraries
# (see https://www.unidata.ucar.edu/software/netcdf/docs/building_netcdf_fortran.html)
################################################################################ 
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
### Additional flags to prevent static build errors
##LDFLAGS+=" -lnetcdf"
CC=mpicc CXX=mpicxx FF=mpif90 FC=mpif90 $BUILD_DIR/$PACKAGE_NAME/configure --prefix=$INSTALL_DIR --enable-shared
##CC=mpicc CXX=mpicxx FF=mpif90 FC=mpif90 $BUILD_DIR/$PACKAGE_NAME/configure --prefix=$INSTALL_DIR --disable-shared
make -j $NCORES
###make check
make install
#
################################################################################
# LFRic environment: Build NETCDF C++ bindings (version 4.2)
# Prerequisites: MPICH (version 3.1.4) and HDF5 (version 1.8.16)
# Note: Configured build with "--enable-shared" for building shared libraries
# (see https://www.unidata.ucar.edu/software/netcdf/docs/building_netcdf_fortran.html)
################################################################################ 
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
### Additional flags to prevent static build errors
###LDFLAGS+=" -lnetcdf"
CC=mpicc CXX=mpicxx FF=mpif90 FC=mpif90 $BUILD_DIR/$PACKAGE_NAME/configure --prefix=$INSTALL_DIR --enable-shared
### CC=mpicc CXX=mpicxx FF=mpif90 FC=mpif90 $BUILD_DIR/$PACKAGE_NAME/configure --prefix=$INSTALL_DIR --disable-shared
make -j $NCORES
###make check
make install
#
################################################################################
# LFRic environment: Build XIOS revision 1700. The recent XIOS trunk from 
# revision 1704 fails with segmentation fault due to changes in function
# void CSourceFilter::buildGraph(CDataPacketPtr packet) in
# src/filter/source_filter.cpp.
# Prerequisites: MPICH (version 3.1.4), HDF5 (version 1.8.16) and
#                NETCDF (version 4.3.3.1)
################################################################################ 
#
# Set XIOS revision
XIOS_VERSION=1700
# XIOS requies perl (should come with Ubuntu 18.04)
# Set paths to HDF5 and NetCDF
export HDF5_DIR=$INSTALL_DIR
export NETCDF_DIR=$INSTALL_DIR
# Set architecture
SYSTEM_NAME="GCC_LINUX"
# Record current directory to make configuration scripts
SCRIPT_DIR=$PWD
# Generate XIOS configuration files for GCC_LINUX
./make_arch_files.sh $SYSTEM_NAME
# Download XIOS source 
cd $BUILD_DIR
svn co --revision=$XIOS_VERSION http://forge.ipsl.jussieu.fr/ioserver/svn/XIOS/trunk XIOS
# Configure and build (parallel build on Linux with GCC)
cd XIOS
# Copy configuration files for GCC_LINUX
cp $SCRIPT_DIR/arch-$SYSTEM_NAME.env arch/arch-$SYSTEM_NAME.env
cp $SCRIPT_DIR/arch-$SYSTEM_NAME.fcm arch/arch-$SYSTEM_NAME.fcm
cp $SCRIPT_DIR/arch-$SYSTEM_NAME.path arch/arch-$SYSTEM_NAME.path
# Make
./make_xios --full --arch $SYSTEM_NAME --job $NCORES
#
################################################################################
# LFRic environment: Build PFUNIT (version 3.2.9)
# Prerequisites: MPICH (version 3.1.4) and CMAKE (here system version)
################################################################################ 
#
# Set PFUNIT version
PFUNIT_VERSION=3.2.9
PACKAGE_DIR="pFUnit-"$PFUNIT_VERSION
# Download and unpack source
cd $BUILD_DIR
wget https://sourceforge.net/projects/pfunit/files/latest/download/$PACKAGE_DIR.tgz
tar -xzf $PACKAGE_DIR.tgz
cd $PACKAGE_DIR
# Set the following environment variables
export F90_VENDOR=GNU
export F90=gfortran
export MPIF90=mpif90
# Install
make -j $NCORES
###make tests
make install

