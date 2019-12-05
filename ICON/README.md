# This folder contains examples of how to build ICON inside a docker container.

### Building the image

First, you need to build the image of the container:

  1. Download PGI Community edition Version 19.10 from
     https://www.pgroup.com/products/community.htm and put it to the './image'
     subdirectory. This particular version of PGI might not be available
     anymore. If this is the case, you either have to find it somewhere else or
     adjust the files in the './image' subdirectory (i.e. the Dockerfile and
     easyblocks) to the version of PGI compiler that you can get.
  2. Switch to the './image' subdirectory: 'cd ./image'.
  3. Build the image: 'docker build -t icon-base:pgi-mpich -f Dockerfile .'.

Once the building is finished, the command 'docker images' should show that the
image has been added to the local Docker registry.

###  Running the image

Now you can run the image:

  docker run -it -v /absoulute/path/to/icon/source/directory:/icon -v /absolute/path/to/poolFolder_prefix:/icon-data-pool --rm icon-base:pgi-mpich-dev

where /absolute/path/to/poolFolder_prefix is a directory on your machine
containing input files for your experiments (e.g. ICON grid files).

At this point you can run the configure wrappers of ICON, which you can find
inside '/icon/config/examples/docker'.
