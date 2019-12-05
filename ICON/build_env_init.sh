# This file contains some helper shell functions, which help to initialize the
# building environment. It is supposed to be sourced inside the script passed
# as BUILD_ENV parameter of the configure script of ICON (see example below).
# It is recommended to keep this script as portable as possible:
# https://www.gnu.org/software/autoconf/manual/autoconf-2.69/html_node/Portable-Shell.html
#
# Example:
# ${ICON_DIR}/configure BUILD_ENV='. ./build_env_init.sh; switch_for_module PrgEnv-cray/6.0.4;'

function switch_for_module {
  if test ! -z $1; then
    packageName=`echo $1 | awk -F/ '{print $(NF-1)}'`
    same_name_modules=`module -t list 2>&1 | sed -n '/^'$packageName'\(\/.*\|$\)/p'`
    test -n "$same_name_modules" && module unload $same_name_modules
    conflicting_modules=`module show $packageName 2>&1 | sed -n 's/^conflict[ \t][ \t]*\([^ \t][^ \t]*\)/\1/p'`
    test -n "$conflicting_modules" && module unload $conflicting_modules
    module load $1
  fi
}

function switch_for_modules {
  for module in $*""; do
    switch_for_module $module
  done 
}
