# === builder
ARG DOCKER_REGISTRY="registry.cloud.mov.ai"
FROM ${DOCKER_REGISTRY}/devops/movai-base-melodic:v1.0.1 AS builder

# Labels
LABEL description="MOV.AI Spawner Base Image"
LABEL maintainer="devops@mov.ai"
LABEL movai="spawner"
LABEL environment="release"

### Environment config
ENV MOVAI_ENV="release" \
    MOVAI_USERSPACE="${MOVAI_HOME}/user" \
    APP_NAME="spawner" \
    REDIS_MASTER_HOST="redis-master" \
    REDIS_MASTER_PORT=6379 \
    REDIS_LOCAL_HOST="redis-local" \
    REDIS_LOCAL_PORT=6379 \
    ROS_VERSION="melodic" \
    PYTHON_VERSION=3.6 \
    ROS1_MOVAI_WS="${MOVAI_HOME}/workspaces/MOVAI_ROS1" \
    ROS2_MOVAI_WS="${MOVAI_HOME}/workspaces/MOVAI_ROS2" \
    ROS1_USER_WS="${MOVAI_HOME}/workspaces/USER_ROS1" \
    ROS2_USER_WS="${MOVAI_HOME}/workspaces/USER_ROS2" \
    ROS_MASTER_URI="http://ros-master:11311/" \
    MOVAI_MANAGER_URI="http://localhost:5004" \
    FLEET_TOKEN=""

# Add user to hardware groups
RUN usermod -aG dialout movai && \
    usermod -aG video movai && \
    usermod -aG audio movai && \
    usermod -aG users movai

# Specific tasks to do to the user homespace
COPY scripts/base/user.rc /tmp/user.rc
RUN /usr/local/bin/user-provision.sh

# Copy packages definition and run install script
COPY --chown=movai:movai docker/$ROS_VERSION/packages/movai.rosinstall /tmp/movai.rosinstall
COPY --chown=movai:movai scripts/base/movai-ros-provision.sh /tmp/movai-ros-provision.sh
COPY docker/$ROS_VERSION/packages/packages.apt /tmp/packages.apt
COPY docker/$ROS_VERSION/packages/requirements.txt /tmp/requirements.txt
COPY scripts/base/packages.bash /tmp/packages.bash
# Copy runtime scripts
COPY scripts/base/movai-packaging.bash /usr/local/lib/movai-packaging.bash
COPY scripts/base/movai-plugins/ /usr/local/lib/movai-plugins/
COPY scripts/base/backup.sh /usr/local/bin/backup.sh
COPY scripts/base/ros1-workspace-build.sh /usr/local/bin/ros1-workspace-build.sh
COPY scripts/base/ros1-workspace-package.sh /usr/local/bin/ros1-workspace-package.sh
COPY scripts/base/enable-custom-rosdep.sh /usr/local/bin/enable-custom-rosdep.sh
COPY scripts/base/setup-pypi-env.bash /usr/local/bin/setup-pypi-env.bash
COPY scripts/base/resources/ /usr/local/share/pypi-confs/resources
COPY scripts/base/provision.sh /usr/local/bin/provision.sh

# enable-custom-rosdep.sh - Create local registry for debian building (temporary. To be moved to ros-buildtools) and Install required packages
# hadolint ignore=DL3004
RUN /usr/local/bin/setup-pypi-env.bash PROD && \
    chown movai /etc/pip.conf && \
    python3 -m pip install mobros && \
    /usr/local/bin/enable-custom-rosdep.sh PROD && \
    # Install required packages
    /usr/local/bin/install-packages.sh && \
    sudo apt autoremove -y && \
    sudo apt-get clean

# Specifc tasks to do to the user homespace
COPY scripts/base/user.rc /tmp/user.rc
RUN /usr/local/bin/user-provision.sh

# Copy custom bash rc
COPY --chown=movai:movai scripts/base/movai.bash ${MOVAI_HOME}/movai.bash

# Copy movai SDK to inside container
COPY --chown=movai:movai sdk/ ${MOVAI_HOME}/sdk/

# Copy runtime scripts
COPY scripts/base/movai-entrypoint.sh /usr/local/bin/movai-entrypoint.sh

SHELL ["/bin/bash", "-o", "pipefail", "-c"]
# hadolint ignore=DL3008
RUN curl -fsSL https://artifacts.cloud.mov.ai/repository/movai-applications/gpg | apt-key add - && \
    add-apt-repository "deb [arch=all] https://artifacts.cloud.mov.ai/repository/ppa-main main main" && \
    apt-get update > /dev/null && \
    apt-get -y --no-install-recommends install movai-spawner && \
    apt-get clean -y > /dev/null && \
    rm -rf /var/cache/apt/* && \
    rm -rf /var/lib/apt/lists/*

# Run everything as mov.ai user
USER movai
