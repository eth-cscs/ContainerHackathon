In order to build the image and manipulate the container, is strongly recommened to be root
to build the images generated, execute the following instructions:

docker build -t ec-earth.mpich3.1.4:latest  -f Dockerfile.ecearth3 .                        

# Take the id generated in your local Docker database
docker tag  9e9d10892615 ec-earth.mpich3.1.4       

# Run the container                                                
docker run --name ec-earth3 --rm -it ec-earth.mpich3.1.4 /bin/bash          

# execute in interactive mode             
docker exec  -it ec-earth3 bash
