# Based on mpi4py by DHNA (https://github.com/dhnza/mpi4py_docker/blob/master/Dockerfile)
# V1.00
# V1.01 including rsync 

# V1.03 : to run with srun and sarus on daint 

FROM ubuntu


# Install system dependencies
# Metis is a library for mesh partitioning:
# http://glaros.dtc.umn.edu/gkhome/metis/metis/overview
RUN apt-get update && apt-get install -y   \
        unzip                       \
        wget                        \
        build-essential             \
        gfortran-5                  \
        strace                      \
        libopenblas-dev             \
        liblapack-dev               \
        python3-dev                 \
        python3-setuptools          \
        python3-pip                 \
        libhdf5-dev                 \
        libmetis-dev                \
        rsync                       \
        --no-install-recommends  && \
    rm -rf /var/lib/apt/lists/*


RUN wget -q http://www.mpich.org/static/downloads/3.1.4/mpich-3.1.4.tar.gz && \
    tar xvf mpich-3.1.4.tar.gz                       && \
    cd mpich-3.1.4                                   && \
    ./configure --disable-fortran --prefix=/usr      && \
    make -j$(nproc)                                  && \
    make install                                     && \
    cd ..                                            && \
    rm -rf mpich-3.1.4.tar.gz mpich-3.1.4            && \
    ldconfig

# Install Python dependencies
RUN pip3 install numpy>=1.8         \
                 pytools>=2016.2.1  \
                 mako>=1.0.0        \
                 appdirs>=1.4.0     \
                 mpi4py>=2.0  

#copy the all the files in the directory that docker file is located 
COPY . /src  

# current working directory when the docker loaded 
WORKDIR /src 
# commond to be executed when docker is loaded 

#CMD [“sh”]

# to run Locally with fixed number of the p = 6
#CMS [“mpirun","-np","6","python", "mpi_stager_v2.py”]

# to run on the HPC which will call this entrypoint with srun 
CMD ["python3","mpi_stager_v2.py"]


#run in terminal: docker build -t wfppdl/parallel_training:v1.0 -f Dockerfile_parallel .