#base image
FROM horovod/horovod:0.16.2-tf1.12.0-torch1.1.0-mxnet1.4.1-py3.5

#copy the source file
COPY . /src

#set up the work dirtory
WORKDIR "/src"

# COMMAND ENTRY BASH
CMD ["bash"]

# run in terminal in source directory: docker build -t wfppdl/training:v1.0 -f ../docker/Dockerfile ../docker
