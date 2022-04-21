# === builder
ARG DOCKER_REGISTRY="registry.aws.cloud.mov.ai"
FROM ${DOCKER_REGISTRY}/devops/movai-base-melodic:v1.4.9 AS builder

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
COPY scripts/base/movai-packaging.bash scripts/base/movai-plugins/ /usr/local/lib/
COPY scripts/base/backup.sh \
    scripts/base/ros1-workspace-build.sh \
    scripts/base/ros1-workspace-package.sh \
    scripts/base/enable-custom-rosdep.sh \
    scripts/base/provision.sh \
    scripts/base/install-packages.sh \
    scripts/base/movai-entrypoint.sh \
    scripts/base/setup-pypi-env.sh \
    #dest dir
    /usr/local/bin/
COPY resources /usr/local/share/pypi-confs/resources

SHELL ["/bin/bash", "-o", "pipefail", "-c"]
# hadolint ignore=DL3008
RUN curl -fsSL https://artifacts.cloud.mov.ai/repository/movai-applications/gpg | apt-key add - && \
    add-apt-repository "deb [arch=all] https://artifacts.cloud.mov.ai/repository/ppa-testing testing main" && \
    # Add our pip repos
    setup-pypi-env.sh INT \
    # enable-custom-rosdep.sh - Create local registry for debian building (temporary. To be moved to ros-buildtools) and Install required packages
    /usr/local/bin/enable-custom-rosdep.sh PROD && \
    # Install required packages
    /usr/local/bin/install-packages.sh && \
    # Clean apt
    apt-get autoremove -y && \
    apt-get clean -y > /dev/null && \
    rm -rf /var/cache/apt/* && \
    rm -rf /var/lib/apt/lists/* && \
    # Clean temp files
    rm -rf /tmp/* && \
    # Temporary link to tools
    ln -sf /usr/local/lib/$PYTHON_VERSION/dist-packages/dal/tools/ /opt/mov.ai/app/tools

# Run everything as mov.ai user
USER movai
