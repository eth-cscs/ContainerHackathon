# Container Hackathon content for the OpenIFS forecasting model

To create the docker image, `cd` to the directory containing the Dockerfile and run:

`docker build -t <image_name> --build-arg http_proxy="$http_proxy" --build-arg ftp_proxy="$ftp_proxy" --build-arg https_proxy="$https_proxy" --build-arg no_proxy="$no_proxy" .`

The above `--build-args` are needed when you are building on a machine using a proxy.
