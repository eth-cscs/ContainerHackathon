#!/bin/bash
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
# Set the compiler environment
COMP_PACKAGE_DIR=$HOME/gnu_env
###mkdir -p $COMP_PACKAGE_DIR
# Set path to installation directory
export INSTALL_DIR=$COMP_PACKAGE_DIR/usr
###mkdir -p $INSTALL_DIR
export PATH=$INSTALL_DIR/bin:$PATH
export LD_LIBRARY_PATH=$INSTALL_DIR/lib:$INSTALL_DIR/lib64:$LD_LIBRARY_PATH
export CPPFLAGS="-I$INSTALL_DIR/include"
export FFLAGS="-I$INSTALL_DIR/include"
export LDFLAGS="-L$INSTALL_DIR/lib"
# Set path to build directory
export BUILD_DIR=$COMP_PACKAGE_DIR/build
###mkdir -p $BUILD_DIR
# Set number of cores for building
NCORES=2
#
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
# Download XIOS source 
cd $BUILD_DIR
svn co --revision=$XIOS_VERSION http://forge.ipsl.jussieu.fr/ioserver/svn/XIOS/trunk XIOS
# Configure and build (parallel build on Linux with GCC)
cd XIOS
# Navigate to "arch" directory to generate configuration files
cd arch
# Generate XIOS configuration files for GCC_LINUX here
cat << EOF > arch-$SYSTEM_NAME".env"
export HDF5_INC_DIR=\$NETCDF_DIR/include
export HDF5_LIB_DIR=\$NETCDF_DIR/lib

export NETCDF_INC_DIR=\$NETCDF_DIR/include
export NETCDF_LIB_DIR=\$NETCDF_DIR/lib
EOF
#
cat << EOF > arch-$SYSTEM_NAME".fcm"
%CCOMPILER      mpicc
%FCOMPILER      mpif90
%LINKER         mpif90  

%BASE_CFLAGS    -w -std=c++11 -D__XIOS_EXCEPTION -D_GLIBCXX_USE_CXX11_ABI=0
%PROD_CFLAGS    -O3 -DBOOST_DISABLE_ASSERTS
%DEV_CFLAGS     -g -O2
%DEBUG_CFLAGS   -g

%BASE_FFLAGS    -D__NONE__ -ffree-line-length-none 
%PROD_FFLAGS    -O3
%DEV_FFLAGS     -g -O2
%DEBUG_FFLAGS   -g 

%BASE_INC       -D__NONE__
%BASE_LD        -lstdc++ -lz -lrt -ldl

%CPP            cpp
%FPP            cpp -P
%MAKE           make
EOF
#
cat << EOF > arch-$SYSTEM_NAME.path
NETCDF_INCDIR="-I \$NETCDF_INC_DIR"
NETCDF_LIBDIR="-L \$NETCDF_LIB_DIR"
NETCDF_LIB="-lnetcdff -lnetcdf"

MPI_INCDIR=""
MPI_LIBDIR=""
MPI_LIB=""

HDF5_INCDIR="-I \$HDF5_INC_DIR"
HDF5_LIBDIR="-L \$HDF5_LIB_DIR"
HDF5_LIB="-lhdf5_hl -lhdf5"
EOF
# Navigate back to the main XIOS directory
cd ../
# Make
echo $PWD
./make_xios --full --arch $SYSTEM_NAME --job $NCORES
#
