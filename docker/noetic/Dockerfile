# === spawner
ARG DOCKER_REGISTRY="pubregistry.aws.cloud.mov.ai"
FROM ${DOCKER_REGISTRY}/ce/movai-base-noetic:v2.4.5 AS spawner

# Labels
LABEL description="MOV.AI Spawner Base Image"
LABEL maintainer="devops@mov.ai"
LABEL movai="spawner"
LABEL environment="release"

### Environment config
ARG APT_REPOSITORY="https://artifacts.aws.cloud.mov.ai/repository"

ENV MOVAI_ENV="release" \
    MOVAI_USERSPACE="${MOVAI_HOME}/user" \
    APP_NAME="spawner" \
    REDIS_MASTER_HOST="redis-master" \
    REDIS_MASTER_PORT=6379 \
    REDIS_LOCAL_HOST="redis-local" \
    REDIS_LOCAL_PORT=6379 \
    ROS_VERSION="noetic" \
    PYTHON_VERSION=3.8 \
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
# Copy custom bash rc
COPY --chown=movai:movai scripts/base/movai.bash ${MOVAI_HOME}/movai.bash
# Copy mobros config
COPY --chown=movai:movai resources/config /etc/mobros/config
# Copy movai SDK to inside container
COPY --chown=movai:movai sdk/ ${MOVAI_HOME}/sdk/
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
# Copy GD_Node script
COPY --chown=movai:movai scripts/base/GD_Node.py ${MOVAI_HOME}/app/GD_Node.py

SHELL ["/bin/bash", "-o", "pipefail", "-c"]
# hadolint ignore=DL3008
RUN curl -fsSL https://raw.githubusercontent.com/ros/rosdistro/master/ros.key -o /usr/share/keyrings/ros.key && \
    curl -fsSL $APT_REPOSITORY/movai-applications/gpg | apt-key add - && \
    add-apt-repository "deb [arch=all] $APT_REPOSITORY/ppa-public main main" && \
    # Add our pip repos
    setup-pypi-env.sh INT \
    # enable-custom-rosdep.sh - Create local registry for debian building (temporary. To be moved to ros-buildtools) and Install required packages
    /usr/local/bin/enable-custom-rosdep.sh PROD && \
    # Install required packages
    /usr/local/bin/install-packages.sh && \
    # Make sure python3 is the only installed one
    apt-get update > /dev/null && \
    apt-get install -y --no-install-recommends python-is-python3 && \
    mkdir -p /opt/mov.ai/docs && \
    chown -R movai:movai /opt/mov.ai/docs && \
    # Clean apt
    apt-get autoremove -y && \
    apt-get clean -y > /dev/null && \
    rm -rf /var/cache/apt/* && \
    rm -rf /var/lib/apt/lists/* && \
    # Clean temp files
    rm -rf /tmp/* && \
    # Temporary link to tools
    ln -s /usr/local/lib/python$PYTHON_VERSION/dist-packages/dal/tools /opt/mov.ai/app/tools

# Run everything as mov.ai user
USER movai

# === spawner-ign
FROM spawner AS spawner-ign

# Labels
LABEL description="MOV.AI Spawner IGN Image"
LABEL maintainer="devops@mov.ai"

USER root

ENV GLOBAL_ROSDEP_SOURCELIST_FILE="/etc/ros/rosdep/sources.list.d/20-default.list"
RUN printf "# yaml for non defined third party dependencies\
    \nyaml https://artifacts.cloud.mov.ai/repository/movai-applications/prod/third-party-translations/rosdep.yaml\n%s"\
    "$(cat $GLOBAL_ROSDEP_SOURCELIST_FILE)" > $GLOBAL_ROSDEP_SOURCELIST_FILE

USER movai

ENV IGNITION_VERSION=fortress

SHELL ["/bin/bash", "-e", "-o", "pipefail", "-c"]
# hadolint ignore=DL3004
RUN curl -fsSL http://packages.osrfoundation.org/gazebo.key | sudo apt-key add - && \
    sudo add-apt-repository "deb http://packages.osrfoundation.org/gazebo/ubuntu-stable $(lsb_release -cs) main" && \
    sudo apt-get install -y --no-install-recommends ros-noetic-movai-ros-ign=1.111.2-3 && \
    sudo apt-get clean -y > /dev/null && \
    rm -rf /opt/mov.ai/user/cache/
