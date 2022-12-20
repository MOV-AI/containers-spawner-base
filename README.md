# Mov.AI Spawner Project

This is the SPAWNER docker project

## Build

Noetic version :

    docker build --pull -t spawner-noetic -f docker/noetic/Dockerfile --target spawner .

Noetic IGN version :

    docker build --pull -t spawner-ign-noetic -f docker/noetic/Dockerfile --target spawner-ign .

## Features

- Initialization of different ROS workspaces :
  - MOVAI_ROS1 needs to be python3 since it serves the GD_Node, for now it is python3
  - USER_ROS1 needs to be the ROS distro specific python version

