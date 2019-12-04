#base image
FROM janvog/cpu_horovod:v1.0

#copy the source file
COPY . /src

#set up the work dirtory
WORKDIR "/src"

ENV PYTHONPATH=/src/hickle/lib/python3.6/site-packages:$PYTHONPATH

# COMMAND ENTRY BASH
CMD ["python", "kitti_train.py"]

# run in terminal in source directory: docker build -t wfppdl/training:v1.0 -f ../docker/Dockerfile ../docker
