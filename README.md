# infrastructure_jenkins_docker

1. Create jenkins docker image
$ ./build_jenkins_docker.sh

2. Create network
$ docker network create my_net

3. Run jenkins docker
$ docker-compose up -d
