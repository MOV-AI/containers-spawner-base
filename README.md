# Mov.AI Spawner Project

This is the SPAWNER docker project

## Build

Melodic version :

    docker build --pull -t spawner-melodic -f docker/melodic/Dockerfile --target spawner .

Noetic version :

    docker build --pull -t spawner-noetic -f docker/noetic/Dockerfile --target spawner .

Melodic IGN version :

    docker build --pull -t spawner-ign-melodic -f docker/melodic/Dockerfile --target spawner-ign .

Noetic IGN version :

    docker build --pull -t spawner-ign-noetic -f docker/noetic/Dockerfile --target spawner-ign .

## Dependencies

This image depends on `movai-base` docker image - https://github.com/MOV-AI/containers-movai-base

## Alternative build
If you have built `movai-base` locally already, you can build `spawner` images using that source by:
1) Changing the Dockerfile `FROM` entry.
2) Removing `--pull` argument 

Example: building spawner-noetic
1) Open file `docker/noetic/Dockerfile`
2) Replace line `FROM ${DOCKER_REGISTRY}/devops/movai-base-noetic:v1.4.9 AS spawner` by `FROM "movai-base:noetic" AS spawner`
3) Call `docker build -t spawner-noetic -f docker/noetic/Dockerfile --target spawner .`


## Features

- Initialization of different ROS workspaces :
  - MOVAI_ROS1 needs to be python3 since it serves the GD_Node, for now it is python3
  - USER_ROS1 needs to be the ROS distro specific python version, in case of melodic is python2

