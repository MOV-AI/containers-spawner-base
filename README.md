# Mov.AI Spawner Project

This is the SPAWNER docker project

## Quick Start with Make

Build all flavors:

    make build-all

Build specific flavor:

    make build-humble

Run interactive container:

    make run-humble

Test image:

    make test-humble

Build ROS1 bridge builder (intermediate stage):

    make build-ros1-bridge-builder

Extract ROS1 bridge tarball:

    make extract-ros1-bridge

For more targets, see:

    make help

## Manual Docker Build

Noetic version :

    docker build --pull -t spawner-noetic -f docker/noetic/Dockerfile --target spawner .

Noetic IGN version :

    docker build --pull -t spawner-ign-noetic -f docker/noetic/Dockerfile --target spawner-ign .

Humble version :

    docker build --pull -t spawner-humble -f docker/humble/Dockerfile --target spawner .

Humble IGN version :

    docker build --pull -t spawner-ign-humble -f docker/humble/Dockerfile --target spawner-ign .

ROS1 Bridge Builder (intermediate stage for building ros1_bridge):

    docker build --pull -t spawner:ros1-bridge-builder -f docker/humble/Dockerfile --target ros1-bridge-builder .

## Features

- Initialization of different ROS workspaces :
  - MOVAI_ROS1 needs to be python3 since it serves the GD_Node, for now it is python3
  - USER_ROS1 needs to be the ROS distro specific python version

