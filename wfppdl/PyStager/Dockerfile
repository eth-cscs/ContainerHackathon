# Based on mpi4py by DHNA (https://github.com/dhnza/mpi4py_docker/blob/master/Dockerfile)


FROM dhna/mpi4py



RUN apt-get update && \
    apt-get -y install rsync &&\
    apt-get clean all 

#copy the all the files in the directory that docker file is located 
COPY . /src  

# current working directory when the docker loaded 
WORKDIR /src 
# commond to be executed when docker is loaded 

CMD [“sh”]

#run in terminal: docker build -t wfppdl/parallel_training:v1.0 -f Dockerfile_parallel .