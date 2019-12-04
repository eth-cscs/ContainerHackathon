#!/usr/bin/env bash

set -xuve

#
# Architecture
#

export MAKE_NUMPROC=4
config='ifs  nemo:elpin  lim3 rnfmapper xios:detached oasis  '
#config=" xios:detached "
config='ifs oasis' 

export PROJECT_DIR=/home/ecearth/ec-earth

export SOURCE_FOLDER=${PROJECT_DIR}/sources
export ECEARTH_SRC_DIR=${SOURCE_FOLDER}
# Variables that could be used from config-build.xml should be exported
export exp_name=t001
NEMO_CONFIG=ORCA1L75_LIM3
# these variables are to be used for development, allowing to retain any local
# changes to the sources and compile the model more quickly
# EXTRACT : extract files from uploaded .tar.gz file and copy runtime files (default:true)
# CLEAN   : do 'make clean' for all model components (default:true)
[ "%MODEL_EXTRACT%" = FALSE ] && MODEL_EXTRACT=false || MODEL_EXTRACT=true
[ "%MODEL_CLEAN%" = FALSE ] && MODEL_CLEAN=false || MODEL_CLEAN=true
MODEL_CLEAN=true
MODEL_CLEAN=false
export MODEL_CLEAN

set +xuve
#  export SCRATCH=/gpfs/scratch/`id -gn`/${USER}
  export architecture=ubuntu-gnu-mpich
#  module purge
#  module load intel/2017.4
#  module load impi/2018.4
#  module load perl/5.26
#  module load mkl/2018.4 # require by python/2.7.14
#  module load python/2.7.14
#   module list
set -xuve

#
# Extract Model Sources and copy runtime, only if MODEL_EXTRACT=TRUE
#
cd ${SOURCE_FOLDER}
util/ec-conf/ec-conf --platform ${architecture}  config-build.xml

set +xuve
source ${SOURCE_FOLDER}/../runtime/classic/librunscript.sh
set -xuve

#
# Check bin and lib directory (git-svn issue with empty folders)
#
if [ ! -d ifs-36r4/bin ]
then
  mkdir ifs-36r4/bin
  mkdir ifs-36r4/lib
fi
if [ ! -d runoff-mapper/bin ]
then
  mkdir runoff-mapper/bin
  mkdir runoff-mapper/lib
fi
if [ ! -d amip-forcing/bin ]
then
  mkdir amip-forcing/bin
  mkdir amip-forcing/lib
fi
if [ ! -d lpjg/build ]
then
  mkdir lpjg/build
fi

# minimum sanity
#has_config amip nemo && error "Cannot have both nemo and amip in config!!"

#
# Complilation of Model Sources
#



# 1) OASIS
if $(has_config oasis)
then
  cd ${SOURCE_FOLDER}/oasis3-mct/util/make_dir
  if ${MODEL_CLEAN} ; then make realclean -f TopMakefileOasis3 BUILD_ARCH=ecconf ; fi
  make -f TopMakefileOasis3 -j ${MAKE_NUMPROC} BUILD_ARCH=ecconf
  # build lucia with the ifort compiler - modify this if you use another compiler
  cd ${SOURCE_FOLDER}/oasis3-mct/util/lucia
  F90=ifort ./lucia -c
fi


# 2) XIOS
if $(has_config xios)
then
  cd ${SOURCE_FOLDER}/xios-2.5
  if ${MODEL_CLEAN} ; then
    ./make_xios --arch ecconf --use_oasis oasis3_mct --netcdf_lib netcdf4_par --job ${MAKE_NUMPROC} --full
  else
    ./make_xios --arch ecconf --use_oasis oasis3_mct --netcdf_lib netcdf4_par --job ${MAKE_NUMPROC}
  fi
  [ -f ${SOURCE_FOLDER}/xios-2.5/bin/xios_server.exe ] || exit 1
fi

# 3) Runoff-Mapper
if $(has_config rnfmapper)
then
  cd ${SOURCE_FOLDER}/runoff-mapper/src
  if ${MODEL_CLEAN} ; then make clean ; fi
  make
  [ -f ${SOURCE_FOLDER}/runoff-mapper/bin/runoff-mapper.exe ] || exit 1
fi

# 4) NEMO
if $(has_config nemo)
then
  cd ${SOURCE_FOLDER}/nemo-3.6/CONFIG
  # remove old nemo executable to make sure compilation did not fail
  # workaround for the issue that make_nemo does not return an exit code on failure
  rm -f ${SOURCE_FOLDER}/nemo*/CONFIG/${NEMO_CONFIG}/BLD/bin/*.exe
  if ${MODEL_CLEAN} ; then ./makenemo -m ecconf -n ${NEMO_CONFIG} -j ${MAKE_NUMPROC} clean ; fi
  ./makenemo -m ecconf -n ${NEMO_CONFIG} -j ${MAKE_NUMPROC}
  [ -f ${SOURCE_FOLDER}/nemo*/CONFIG/${NEMO_CONFIG}/BLD/bin/*.exe ] || exit 1
fi

# 5) IFS
if $(has_config ifs)
then
  set +xuve
  . ${SOURCE_FOLDER}/util/grib_table_126/define_table_126.sh
  set -xuve
  cd ${SOURCE_FOLDER}/ifs-36r4
  if ${MODEL_CLEAN} ; then
    make clean BUILD_ARCH=ecconf
    make realclean BUILD_ARCH=ecconf
    make dep-clean BUILD_ARCH=ecconf
  fi
  make -j ${MAKE_NUMPROC} BUILD_ARCH=ecconf lib
  make BUILD_ARCH=ecconf master
  [ -f ${SOURCE_FOLDER}/ifs*/bin/ifsmaster* ] || exit 1
fi

# 6) Amip
if $(has_config amip)
then
  cd ${SOURCE_FOLDER}/amip-forcing/src
  if ${MODEL_CLEAN} ; then make clean ; fi
  make
  [ -f ${SOURCE_FOLDER}/amip*/bin/amip* ] || exit 1
fi

# 7) LPJ-Guess
if $(has_config lpjg)
then
  lpjg_res=T$(echo ${IFS_resolution} | sed 's:T\([0-9]\+\)L\([0-9]\+\):\1:')
  if [ $lpjg_res != "T255" -a $lpjg_res != "T159" ]
  then
    echo "LPJG-gridlist doesn't exist for ifs-grid: ${IFS_resolution}"
    exit 1
  fi
  cd ${SOURCE_FOLDER}/lpjg/build
  set +xuve
  module load cmake
  [ ${HPCARCH} == 'marenostrum4' ] && module load grib/1.14.0
  set -xuve
  if ${MODEL_CLEAN} ; then rm -f CMakeCache.txt ; fi
  cmake -D GRID=${lpjg_res} ..
  if ${MODEL_CLEAN} ; then make clean ; fi
  make -j ${MAKE_NUMPROC}
  [ -f ${SOURCE_FOLDER}/lpjg/build/guess_${lpjg_res} ] || exit 1

  cd ${SOURCE_FOLDER}/lpjg/offline
  if ${MODEL_CLEAN} ; then make clean ; fi
  make
  [ -f ${SOURCE_FOLDER}/lpjg/offline/lpjg_forcing_ifs ] || exit 1
fi

# 8) TM5
if $(has_config tm5)
then
  has_config tm5:co2 && tmversion="co2" || tmversion="cb05"
  export tm5_exch_nlevs=${TM5_NLEVS}
  tm5_exe_file=${SOURCE_FOLDER}/tm5mp/build-${tmversion}-ml${tm5_exch_nlevs}/appl-tm5-${tmversion}.x
  cd ${SOURCE_FOLDER}/tm5mp/
  if [ ! -f ${SOURCE_FOLDER}/tm5mp/setup_tm5 ] ; then
      ln -sf ${SOURCE_FOLDER}/tm5mp/bin/pycasso_setup_tm5 ${SOURCE_FOLDER}/tm5mp/setup_tm5
      chmod 755 setup_tm5
  fi
  if ${MODEL_CLEAN}
  then
      ./setup_tm5 -c -n -v -j ${MAKE_NUMPROC} ecconfig-ecearth3.rc
  else
      ./setup_tm5       -v -j ${MAKE_NUMPROC} ecconfig-ecearth3.rc
  fi
  [ -f ${tm5_exe_file} ] || exit 1
fi

# 9) ELPiN
if $(has_config elpin)
then
 cd ${SOURCE_FOLDER}/util/ELPiN/
 make clean
 make
fi

echo "Finished compiling"

