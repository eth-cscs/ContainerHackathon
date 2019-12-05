# Based on mpi4py by DHNA (https://github.com/dhnza/mpi4py_docker/blob/master/Dockerfile)
# V1.00
# V1.01 including rsync 

# V1.03 : to run with srun and sarus on daint 

FROM dhna/mpi4py



RUN apt-get update && \
    apt-get -y install rsync &&\
    apt-get clean all 

#copy the all the files in the directory that docker file is located 
COPY . /src  

# current working directory when the docker loaded 
WORKDIR /src 
# commond to be executed when docker is loaded 

#CMD [“sh”]

# to run Locally with fixed number of the p = 6
#CMS [“mpirun","-np","6","python", "mpi_stager_v2.py”]

# to run on the HPC which will call this entrypoint with srun 
CMD ["python","mpi_stager_v2.py"]


#run in terminal: docker build -t wfppdl/parallel_training:v1.0 -f Dockerfile_parallel .