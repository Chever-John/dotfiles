#!/usr/bin/env bash

docker rm $(docker ps -qf 'status=exited')

docker rmi $(docker images -qf 'dangling=true')
docker rmi $(docker images -a)
docker rmi $(docker images -a) -f

docker volume rm $(docker volume ls -qf 'dangling=true')

sudo docker system df
sudo docker volume prune
