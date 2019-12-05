#!/bin/bash
################################################################################
# LFRic environment: Build arch files for XIOS (revision 1700).
# Additional flags for undefined references to dlsym, dlopen and dlclose in
# linking XIOS (warning in linking HDF5, see e.g.
# http://hdf-forum.184993.n3.nabble.com/Errors-compiling-against-Static-build-HDF5-1-8-11-Need-for-ldl-added-to-linker-arguments-td4026300.html
# LDFLAGS+=" -lz -lrt -ldl -lm -Wl,-rpath -Wl,$HDF5_LIB_DIR"
# Here only "-lrt" and "-ldl" LDFLAGS  added to %BASE_LD in *.fcm file
################################################################################ 

SYSTEM_NAME=$1

cat << EOF > arch-$SYSTEM_NAME".env"
export HDF5_INC_DIR=\$NETCDF_DIR/include
export HDF5_LIB_DIR=\$NETCDF_DIR/lib

export NETCDF_INC_DIR=\$NETCDF_DIR/include
export NETCDF_LIB_DIR=\$NETCDF_DIR/lib
EOF

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
