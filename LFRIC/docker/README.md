# How to build a Docker container of LFRic

## Gungho benchmark

As outlined in
[*LFRic and PSyclone repositories and code*](https://github.com/eth-cscs/ContainerHackathon/blob/master/LFRIC/LFRicPSycloneRepoCode.md)
section, the LFRic trunk is divided into several applications. This section
outlines how to build a container benchmark of the Gungho application.

A template Dockerfile to build the `LFRic` Gungho container is available below:
```
#################################################################################
# LFRic environment: Builds and runs LFRic Gungho benchmark with PSyclone OMP.
# Prerequisites: LFRic build environment built with the system  GCC compiler
                 (version 7.4.0) using Docker template 'lfric_deps.docker' and
                 the relevant installation scripts.
#################################################################################
#
FROM lfric-deps:gnu
#
# Define home and working directories
ENV HOME /usr/local/src
WORKDIR /usr/local/src
#
# Set the compiler environment
ENV COMP_PACKAGE_DIR $HOME/gnu_env
# Set the following environment variables
ENV INSTALL_DIR $COMP_PACKAGE_DIR/usr
ENV BUILD_DIR $COMP_PACKAGE_DIR/build
ENV PFUNIT $INSTALL_DIR
ENV PATH $INSTALL_DIR/bin:$PATH
ENV FC gfortran
ENV FPP "cpp -traditional-cpp"
ENV LDMPI mpif90
ENV FFLAGS "-I$BUILD_DIR/XIOS/inc -I$INSTALL_DIR/include -I$INSTALL_DIR/mod"
ENV LDFLAGS "-L$BUILD_DIR/XIOS/lib -L$INSTALL_DIR/lib -L/usr/lib -lstdc++"
ENV CPPFLAGS "-I$INSTALL_DIR/include -I/usr/include"
ENV LD_LIBRARY_PATH $INSTALL_DIR/lib:$INSTALL_DIR/lib64:$LD_LIBRARY_PATH
# Path to PSyclone configuration file
ENV PSYCLONE_CONFIG /usr/local/share/psyclone/psyclone.cfg
#
# Adds config file for MPICH for Sarus on Piz Daint
RUN echo "/usr/local/src/gnu_env/usr/lib" > /etc/ld.so.conf.d/mpich.conf \
 && ldconfig
#
# For most applications one OMP thread is enough (can be set in batch submit script)
ENV OMP_NUM_THREADS 1
#
# Set option to apply OpenMP optimisations with PSyclone
ENV LFRIC_TARGET_PLATFORM meto-spice
#
# Copy LFRic trunk inside the container
COPY LFRic_trunk.tar .
# Unpack LFRic trunk
RUN tar -xf LFRic_trunk.tar \
# Navigate to "gungho" directory and build application
 && cd LFRic_trunk/gungho \
 && make build -j \
# Navigate to example directory to run the application from
 && cd example
#
# Paths to executables and example directory
ENV PATH $HOME/LFRic_trunk/gungho/bin:$PATH
WORKDIR $HOME/LFRic_trunk/gungho/example
``` 

We have saved the template Dockerfile above as `lfric_gungho.docker` and we built
it with the command below:

```
docker build --network=host --add-host $HOSTNAME:127.0.0.1 -f lfric_gungho.docker -t lfric-gungho:gnu .
```

The template starts the build from the `lfric-deps:gnu` Docker container which
contains the libraries needed by the code: `MPICH`, `YAXT`, `HDF5`, `NetCDF`,
`NetCDF-Fortran`, `NetCDF-C++`, `XIOS` and `pFUnit`. This dependency container
was  built from the script
[lfric_deps.docker](https://github.com/eth-cscs/ContainerHackathon/blob/master/LFRIC/docker/lfric_deps.docker)
by running

```
docker build --network=host --add-host $HOSTNAME:127.0.0.1 -f lfric_deps.docker -t lfric-deps:gnu .
```

The scripts that build the libraries are also provided in the repository:
- [install_lfric_env.sh](https://github.com/eth-cscs/ContainerHackathon/blob/master/LFRIC/docker/install_lfric_env.sh)
  sets up the environment and builds the dependencies of `LFRic` without the `XIOS`;
- [install_xios_env.sh](https://github.com/eth-cscs/ContainerHackathon/blob/master/LFRIC/docker/install_xios_env.sh)
  creates architecture files needed to build `XIOS` and builds `XIOS`.

Instructions on how to run the LFRic Gungho container with Sarus on Piz Daint and
results of the runs can be found in
[*How to run the LFRic container with Sarus on Piz Daint*](https://github.com/eth-cscs/ContainerHackathon/blob/master/LFRIC/docker/RunsResults.md)
section.

## Gravity Wave benchmark

This section outlines how to build a container benchmark of the Gravity Wave
application, one of the LFRic miniapps (see
[*LFRic and PSyclone repositories and code*](https://github.com/eth-cscs/ContainerHackathon/blob/master/LFRIC/LFRicPSycloneRepoCode.md)
section for more details).

A template Dockerfile to build the `LFRic` Gravity Wave container is available below:
```
#################################################################################
# LFRic environment: Builds and runs LFRic Gravity Wave benchmark.
# Prerequisites: LFRic build environment built with the system  GCC compiler
                 (version 7.4.0) using Docker template 'lfric_deps.docker' and
                 the relevant installation scripts.
#################################################################################
#
FROM lfric-deps:gnu
#
# Define home and working directories
ENV HOME /usr/local/src
WORKDIR /usr/local/src
#
# Set the compiler environment
ENV COMP_PACKAGE_DIR $HOME/gnu_env
# Set the following environment variables
ENV INSTALL_DIR $COMP_PACKAGE_DIR/usr
ENV BUILD_DIR $COMP_PACKAGE_DIR/build
ENV PFUNIT $INSTALL_DIR
ENV PATH $INSTALL_DIR/bin:$PATH
ENV FC gfortran
ENV FPP "cpp -traditional-cpp"
ENV LDMPI mpif90
ENV FFLAGS "-I$BUILD_DIR/XIOS/inc -I$INSTALL_DIR/include -I$INSTALL_DIR/mod"
ENV LDFLAGS "-L$BUILD_DIR/XIOS/lib -L$INSTALL_DIR/lib -L/usr/lib -lstdc++"
ENV CPPFLAGS "-I$INSTALL_DIR/include -I/usr/include"
ENV LD_LIBRARY_PATH $INSTALL_DIR/lib:$INSTALL_DIR/lib64:$LD_LIBRARY_PATH
# Path to PSyclone configuration file
ENV PSYCLONE_CONFIG /usr/local/share/psyclone/psyclone.cfg
#
# Adds config file for MPICH for Sarus on Piz Daint
RUN echo "/usr/local/src/gnu_env/usr/lib" > /etc/ld.so.conf.d/mpich.conf \
 && ldconfig
#
# For most applications one OMP thread is enough (can be set in batch submit script)
ENV OMP_NUM_THREADS 1
#
# Copy LFRic trunk inside the container
COPY LFRic_trunk.tar .
# Unpack LFRic trunk
RUN tar -xf LFRic_trunk.tar \
# Navigate to "gravity_wave" directory and build application
 && cd LFRic_trunk/miniapps/gravity_wave \
 && make build -j \
# Navigate to example directory to run the application from
 && cd example
#
# Paths to executables and example directory
ENV PATH $HOME/LFRic_trunk/miniapps/gravity_wave/bin:$PATH
WORKDIR $HOME/LFRic_trunk/miniapps/gravity_wave/example
```

The above template was saved as `lfric_gwave.docker` and build with the command
below:

```
docker build --network=host --add-host $HOSTNAME:127.0.0.1 -f lfric_gwave.docker -t lfric-gwave:gnu .
```

As for the Gungho benchmark, the template starts the build from the
`lfric-deps:gnu` Docker container.

An overview of running the Gravity Wave container with Sarus on Piz Daint can
also be found in
[*How to run the LFRic container with Sarus on Piz Daint*](https://github.com/eth-cscs/ContainerHackathon/blob/master/LFRIC/docker/RunsResults.md)
section.

## Library versions and settings

* All libraries were dynamically linked to make sure that the `LFRic` container
  will use the optimized libraries of the host system: the `install_lfric_env.sh`
  script contains commented out instructions for a static build if required.

* The `MPICH` version used in the current Met Office (MO) `LFRic` build system is 3.3.
  Here we used version 3.1.4 to ensure ABI compatibility with the Cray MPI library available
  on Piz Daint: please have a look at
  [the MPICH Wiki](https://wiki.mpich.org/mpich/index.php/ABI_Compatibility_Initiative)
  for more information on the ABI Compatibility Initiative.

* `HDF5`, `NetCDF`, `NetCDF-Fortran`, `NetCDF-C++` and `pFUnit` are also slightly
   older than in the current MO `LFRic` build system, whereas `YAXT` is the same version.

* [`XIOS`](https://forge.ipsl.jussieu.fr/ioserver) is a tricky beast to build as
  not every revision/release will work with every compiler and/or every compiler release.
  For instance, the MO GCC 6.1.0 environment uses revision 1537 which is too old
  for GCC 7.4.0 used here. Unfortunately, the current `XIOS` trunk produces a build which
  segfaults at runtime for the GCC release and other libraries used in this container.
  There is, however, a relatively recent revision before the segfault bug that
  was appropriate for this container.

* Here we used the same `PSyclone` release (1.7.0) that is used by the current
 `LFRic` trunk (as of 4 December 2019), built with Python 2 environment (the move
  to Python 3 and newest `PSyclone` is under way????). Not every `PSyclone` release
  will work with every `LFRic` trunk revision. The `LFRic` - `PSyclone` compatibility
  table is give in this
  [`LFRic` wiki (requires login)](https://code.metoffice.gov.uk/trac/lfric/wiki/LFRicTechnical/VersionsCompatibility).

## Tips & tricks

* The container tool [Sarus](https://user.cscs.ch/tools/containers/sarus) supported
  on Piz Daint can add the proper hook to the host MPI library if the command
  `ldconfig` has been run to configure dynamic linker run-time bindings. Since we
  have installed the `MPICH` library in a non-default location, the command
  `ldconfig` would not be able to find the library in the custom path within the
  container. Therefore, before running `ldconfig` we added the path of `MPICH` to
  `/etc/ld.so.conf.d/mpich.conf` as in the example below:
  ```
  # Adds config file for MPICH for Sarus on Piz Daint
  RUN echo "/usr/local/src/gnu_env/usr/lib" > /etc/ld.so.conf.d/mpich.conf \
   && ldconfig
  ```
  Please look [here](https://unix.stackexchange.com/questions/425251/using-ldconfig-and-ld-so-conf-versus-ld-library-path)
  for more information.

* Some libraries (e.g. `YAXT`) perform a test run of a minimal MPI code during
  the configure step of the installation procedure: the test might fail within
  the Docker container if the local hostname cannot be resolved correctly. In
  order to do that, the local hostname should be available in the file `/etc/hosts`,
  which can be achieved adding the option `--add-hostname $HOSTNAME:127.0.0.1` to
  Docker build command.
  If this solution does not work, one needs to edit the `/etc/hosts` file of the
  Docker container directly using `docker run` and commit the change with
  `docker commit`, since editing the `/etc/hosts` file is not possible within
  the Dockerfile. For more details, please check
  [this link](https://stackoverflow.com/questions/23112515/mpich2-gethostbyname-failed/23118973).

* Checking out the `LFRic` trunk requires access to the MO
  [`LFRic` repository](https://code.metoffice.gov.uk/trac/lfric/browser/LFRic).

* Once the `LFRic` trunk is checked out, the `Makefile`s of  tested Gungho and
  Gravity Wave applications needed to be modified from
  ```
  export EXTERNAL_DYNAMIC_LIBRARIES = yaxt yaxt_c netcdff netcdf hdf5 \
                                      $(CXX_RUNTIME_LIBRARY)
  export EXTERNAL_STATIC_LIBRARIES = xios
  ```
  to
  ```
  export EXTERNAL_DYNAMIC_LIBRARIES =
  export EXTERNAL_STATIC_LIBRARIES = yaxt yaxt_c xios netcdff netcdf hdf5_hl \
                                     hdf5 z :libstdc++.a
  ```
  for the build to complete. For this reason we made changes to `Makefile`s
  outside the container and then copied the tarballs into the container.

* By default, running command-line `make` builds `LFRic` with MPI but not OpenMP.
  To enable `PSyclone` OpenMP optimisations, the environment variable
  `LFRIC_TARGET_PLATFORM` was set to `meto-spice` value.

