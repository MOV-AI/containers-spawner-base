ARG DOCKER_REGISTRY="pubregistry.aws.cloud.mov.ai"
ARG BASE_IMAGE="ce/movai-base-humble"
ARG BASE_IMAGE_TAG="2.7.5"
# === ros1-bridge-builder
FROM ros:humble-ros-base-jammy AS ros1-bridge-builder
# Imported from: https://github.com/TommyChangUMD/ros-humble-ros1-bridge-builder

# Make sure bash catches errors (no need to chain commands with &&, use ; instead)
SHELL ["/bin/bash", "-o", "pipefail", "-o", "errexit", "-c"]

###########################
# 1.) Bring system up to the latest ROS desktop configuration
###########################
RUN apt-get -y update
RUN apt-get -y upgrade
RUN apt-get -y install ros-humble-desktop

###########################
# 2.) Temporarily remove ROS2 apt repository
###########################
RUN mv /etc/apt/sources.list.d/ros2.sources /root/
RUN apt-get update

###########################
# 3.) comment out the catkin conflict
###########################
RUN sed  -i -e 's|^Conflicts: catkin|#Conflicts: catkin|' /var/lib/dpkg/status
RUN apt-get install -f

###########################
# 4.) force install these packages
###########################
RUN apt-get download python3-catkin-pkg
RUN apt-get download python3-rospkg
RUN apt-get download python3-rosdistro
RUN dpkg --force-overwrite -i python3-catkin-pkg*.deb
RUN dpkg --force-overwrite -i python3-rospkg*.deb
RUN dpkg --force-overwrite -i python3-rosdistro*.deb
RUN apt-get install -f

###########################
# 5.) Install the latest ROS1 desktop configuration
# see https://packages.ubuntu.com/jammy/ros-desktop-dev
# note: ros-desktop-dev automatically includes tf tf2
###########################
RUN apt-get -y install ros-desktop-dev

# fix ARM64 pkgconfig path issue -- Fix provided by ambrosekwok
RUN if [[ $(uname -m) = "arm64" || $(uname -m) = "aarch64" ]]; then                     \
      cp /usr/lib/x86_64-linux-gnu/pkgconfig/* /usr/lib/aarch64-linux-gnu/pkgconfig/;   \
    fi

###########################
# 6.) Restore the ROS2 apt repos and set compilation options.
#   For example, to include ROS tutorial message types, pass
#   "--build-arg ADD_ros_tutorials=1" to the docker build command.
###########################
RUN mv /root/ros2.sources /etc/apt/sources.list.d/
RUN apt-get -y update

# for ros-humble-example-interfaces:
ARG ADD_ros_tutorials=1

# for ros-humble-grid-map:
ARG ADD_grid_map=0

# for a custom message example
ARG ADD_example_custom_msgs=0

# for octomap
ARG ADD_octomap_msgs=0

# for custom action mapping
ARG ADD_custom_action_mapping=1

# sanity check:
RUN echo "ADD_ros_tutorials         = '$ADD_ros_tutorials'"
RUN echo "ADD_grid_map              = '$ADD_grid_map'"
RUN echo "ADD_example_custom_msgs   = '$ADD_example_custom_msgs'"
RUN echo "ADD_octomap_msgs          = '$ADD_octomap_msgs'"
RUN echo "ADD_custom_action_mapping = '$ADD_custom_action_mapping'"

###########################
# 6.1) Add ROS1 ros_tutorials messages and services
# eg., See AddTwoInts server and client tutorial
###########################
RUN if [[ "$ADD_ros_tutorials" = "1" ]]; then                                           \
      git clone -b noetic-devel --depth=1 https://github.com/ros/ros_tutorials.git;     \
      cd ros_tutorials;                                                                 \
      unset ROS_DISTRO;                                                                 \
      time colcon build --cmake-args -DCMAKE_BUILD_TYPE=Release;                        \
      # for actionlib_tutorials                                                         \
      cd ..;                                                                            \
      source ros_tutorials/install/setup.bash;                                          \
      git clone -b fuerte-devel --depth=1 https://github.com/ros/common_tutorials.git;  \
      cd common_tutorials;                                                              \
      unset ROS_DISTRO;                                                                 \
      time colcon build --cmake-args -DCMAKE_BUILD_TYPE=Release;                        \
    fi

# unit test (optional)
# RUN if [[ "$ADD_ros_tutorials" = "1" ]]; then           \
#       cd ros_tutorials;                                 \
#       unset ROS_DISTRO;                                 \
#       colcon test --event-handlers console_direct+;     \
#       colcon test-result;                               \
#     fi

###########################
# 6.2 Add ROS1 grid-map messages
###########################
# navigation stuff (just need costmap_2d?)
RUN if [[ "$ADD_grid_map" = "1" ]]; then                                                        \
      apt-get -y install libsdl1.2-dev libsdl-image1.2-dev;                                     \
      git clone -b noetic-devel --depth=1 https://github.com/ros-planning/navigation.git;       \
      cd navigation;                                                                            \
      unset ROS_DISTRO;                                                                         \
      time colcon build --cmake-args -DCMAKE_BUILD_TYPE=Release                                 \
        --packages-select map_server voxel_grid costmap_2d;                                     \
    fi

# filter stuff
RUN if [[ "$ADD_grid_map" = "1" ]]; then                                        \
      git clone -b noetic-devel --depth=1 https://github.com/ros/filters.git;   \
      cd filters;                                                               \
      unset ROS_DISTRO;                                                         \
      time colcon build --cmake-args -DCMAKE_BUILD_TYPE=Release;                \
    fi

# finally grid-amp (only select a subset for now)
RUN if [[ "$ADD_grid_map" = "1" ]]; then                                                \
      apt-get -y install libpcl-ros-dev libcv-bridge-dev;                               \
      source navigation/install/setup.bash;                                             \
      source filters/install/setup.bash;                                                \
      git clone -b 1.6.4 --depth=1 https://github.com/ANYbotics/grid_map.git;           \
      cd grid_map;                                                                      \
      unset ROS_DISTRO;                                                                 \
      grep -r c++11 | grep CMakeLists | cut -f 1 -d ':' |                               \
        xargs sed -i -e 's|std=c++11|std=c++17|g';                                      \
      time colcon build --cmake-args -DCMAKE_BUILD_TYPE=Release                         \
        --packages-select grid_map_msgs grid_map_core grid_map_octomap grid_map_sdf     \
        grid_map_costmap_2d grid_map_cv grid_map_ros grid_map_loader;                   \
    fi

######################################
# 6.3) Compile custom message (code provided by Codaero)
#   Note1: Make sure the package name ends with "_msgs".
#   Note2: Use the same package name for both ROS1 and ROS2.
#   See https://github.com/ros2/ros1_bridge/blob/master/doc/index.rst
######################################
RUN if [[ "$ADD_example_custom_msgs" = "1" ]]; then                     \
      git clone https://github.com/TommyChangUMD/custom_msgs.git;       \
      #                                                                 \
      # Compile for ROS1:                                               \
      #                                                                 \
      cd /custom_msgs/custom_msgs_ros1;                                 \
      unset ROS_DISTRO;                                                 \
      time colcon build --cmake-args -DCMAKE_BUILD_TYPE=Release;        \
      #                                                                 \
      # Compile for ROS2:                                               \
      #                                                                 \
      cd /custom_msgs/custom_msgs_ros2;                                 \
      source /opt/ros/humble/setup.bash;                                \
      time colcon build --cmake-args -DCMAKE_BUILD_TYPE=Release;        \
    fi


###########################
# 6.4 Add ROS1 octomap message
###########################
RUN if [[ "$ADD_octomap_msgs" = "1" ]]; then                                    \
    git clone --depth 1 -b 0.3.5 https://github.com/OctoMap/octomap_msgs.git;   \
    cd octomap_msgs/;                                                           \
    unset ROS_DISTRO;                                                           \
    time colcon build --cmake-args -DCMAKE_BUILD_TYPE=Release;                  \
fi

###########################
# 6.5) Example custom action mapping
# Using YAML file for custom action mapping of control_msgs actions (code provided by Doug Smith)
###########################
RUN if [[ "$ADD_custom_action_mapping" = "1" ]]; then                                                          \
      cd /;                                                                                                    \
      # cloning the control_msgs repository for ROS1 and ROS2, which contains the action messages to be mapped.\
      git clone --depth=1 -b kinetic-devel https://github.com/ros-controls/control_msgs.git control_msgs_ros1; \
      cd /control_msgs_ros1;                                                                                   \
      unset ROS_DISTRO;                                                                                        \
      time colcon build --cmake-args -DCMAKE_BUILD_TYPE=Release;                                               \
      cd /;                                                                                                    \
      git clone --depth=1 -b humble https://github.com/ros-controls/control_msgs.git control_msgs_ros2;        \
      cd /control_msgs_ros2;                                                                                   \
      unset ROS_DISTRO;                                                                                        \
      source /opt/ros/humble/setup.bash;                                                                       \
      time colcon build --cmake-args -DCMAKE_BUILD_TYPE=Release;                                               \
      # adding the custom action mapping repository, which contains the YAML file for action mapping.          \
      mkdir -p /custom_action/src;                                                                             \
      cd /custom_action/src;                                                                                   \
      git clone --depth=1 https://github.com/smith-doug/bridge_mapping.git;                                    \
      cd /custom_action;                                                                                       \
      source /opt/ros/humble/setup.bash;                                                                       \
      time colcon build --cmake-args -DCMAKE_BUILD_TYPE=Release;                                               \
    fi

###########################
# 7.) Compile ros1_bridge
###########################
RUN                                                                                             \
    #-------------------------------------                                                      \
    # Apply the ROS2 underlay                                                                   \
    #-------------------------------------                                                      \
    source /opt/ros/humble/setup.bash;                                                          \
    #                                                                                           \
    #-------------------------------------                                                      \
    # Apply additional message / service overlays                                               \
    #-------------------------------------                                                      \
    if [[ "$ADD_ros_tutorials" = "1" ]]; then                                                   \
      # Apply ROS1 package overlay                                                              \
      source ros_tutorials/install/setup.bash;                                                  \
      source common_tutorials/install/setup.bash;                                                  \
      # Apply ROS2 package overlay                                                              \
      apt-get -y install ros-humble-example-interfaces ros-humble-action-tutorials-interfaces;  \
      apt-get -y install ros-humble-action-tutorials-cpp ros-humble-action-tutorials-py;        \
      source /opt/ros/humble/setup.bash;                                                        \
    fi;                                                                                         \
    #                                                                                           \
    if [[ "$ADD_grid_map" = "1" ]]; then                                                        \
      # Apply ROS1 package overlay                                                              \
      source grid_map/install/setup.bash;                                                       \
      # Apply ROS2 package overlay                                                              \
      apt-get -y install ros-humble-grid-map;                                                   \
      source /opt/ros/humble/setup.bash;                                                        \
    fi;                                                                                         \
    #                                                                                           \
    if [[ "$ADD_example_custom_msgs" = "1" ]]; then                                             \
      # Apply ROS1 package overlay                                                              \
      source /custom_msgs/custom_msgs_ros1/install/setup.bash;                                  \
      # Apply ROS2 package overlay                                                              \
      source /custom_msgs/custom_msgs_ros2/install/setup.bash;                                  \
    fi;                                                                                         \
    #                                                                                           \
    if [[ "$ADD_octomap_msgs" = "1" ]]; then                                                    \
      # Apply ROS1 package overlay                                                              \
      source octomap_msgs/install/setup.bash;                                                   \
      # Apply ROS2 package overlay                                                              \
      apt-get -y install ros-humble-octomap-msgs;                                               \
      source /opt/ros/humble/setup.bash;                                                        \
    fi;                                                                                         \
    # Source overlays for mapping and industrial messages if present
    if [[ "$ADD_custom_action_mapping" = "1" ]]; then \
      source /control_msgs_ros1/install/setup.bash; \
      source /control_msgs_ros2/install/setup.bash; \
      source /custom_action/install/setup.bash; \
    fi; \
    #                                                                                           \
    #-------------------------------------                                                      \
    # Finally, build the Bridge                                                                 \
    #-------------------------------------                                                      \
    mkdir -p /ros-humble-ros1-bridge/src;                                                       \
    cd /ros-humble-ros1-bridge/src;                                                             \
    git clone -b action_bridge_humble --depth=1 https://github.com/smith-doug/ros1_bridge.git;  \
    cd ros1_bridge/;                                                                            \
    cd ../..;                                                                                   \
    MEMG=$(printf "%.0f" $(free -g | awk '/^Mem:/{print $2}'));                                 \
    NPROC=$(nproc);  MIN=$((MEMG<NPROC ? MEMG : NPROC));                                        \
    #                                                                                           \
    echo "Please wait...  running $MIN concurrent jobs to build ros1_bridge";                   \
    time MAKEFLAGS="-j $MIN" colcon build --event-handlers console_direct+                      \
      --cmake-args -DCMAKE_BUILD_TYPE=Release

###########################
# 8.) Clean up
###########################
RUN apt-get -y clean all; apt-get -y update

###########################
# 9.) Pack all ROS1 dependent libraries
###########################
# fix ARM64 pkgconfig path issue -- Fix provided by ambrosekwok
RUN if [[ $(uname -m) = "arm64" || $(uname -m) = "aarch64" ]]; then                    \
      cp /usr/lib/x86_64-linux-gnu/pkgconfig/* /usr/lib/aarch64-linux-gnu/pkgconfig/;  \
    fi

RUN ROS1_LIBS="libxmlrpcpp.so";                                                 \
     ROS1_LIBS="$ROS1_LIBS librostime.so";                                      \
     ROS1_LIBS="$ROS1_LIBS libroscpp.so";                                       \
     ROS1_LIBS="$ROS1_LIBS libroscpp_serialization.so";                         \
     ROS1_LIBS="$ROS1_LIBS librosconsole.so";                                   \
     ROS1_LIBS="$ROS1_LIBS librosconsole_log4cxx.so";                           \
     ROS1_LIBS="$ROS1_LIBS librosconsole_backend_interface.so";                 \
     ROS1_LIBS="$ROS1_LIBS liblog4cxx.so";                                      \
     ROS1_LIBS="$ROS1_LIBS libcpp_common.so";                                   \
     ROS1_LIBS="$ROS1_LIBS libb64.so";                                          \
     ROS1_LIBS="$ROS1_LIBS libaprutil-1.so";                                    \
     ROS1_LIBS="$ROS1_LIBS libapr-1.so";                                        \
     ROS1_LIBS="$ROS1_LIBS libactionlib.so.1d";                                 \
     cd /ros-humble-ros1-bridge/install/ros1_bridge/lib;                        \
     for soFile in $ROS1_LIBS; do                                               \
       soFilePath=$(ldd libros1_bridge.so | grep $soFile | awk '{print $3;}');  \
       cp $soFilePath ./;                                                       \
     done

###########################
# 10.) Create ros1_bridge tarball
###########################
RUN tar czf /ros-humble-ros1-bridge.tgz \
     --exclude '*/build/*' --exclude '*/src/*' /ros-humble-ros1-bridge

# === spawner
FROM ${DOCKER_REGISTRY}/${BASE_IMAGE}:${BASE_IMAGE_TAG} AS spawner

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
    PYTHON_VERSION=3.8 \
    ROS1_MOVAI_WS="${MOVAI_HOME}/workspaces/MOVAI_ROS1" \
    ROS2_MOVAI_WS="${MOVAI_HOME}/workspaces/MOVAI_ROS2" \
    ROS1_USER_WS="${MOVAI_HOME}/workspaces/USER_ROS1" \
    ROS2_USER_WS="${MOVAI_HOME}/workspaces/USER_ROS2" \
    ROS_MASTER_URI="http://ros-master:11311/" \
    MOVAI_MANAGER_URI=""

# Add user to hardware groups
USER root
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
# Copy ROS1 bridge from builder stage (extracted from tarball)
COPY --from=ros1-bridge-builder /ros-humble-ros1-bridge.tgz /ros2_ws/

SHELL ["/bin/bash", "-o", "pipefail", "-c"]
# hadolint ignore=DL3008
RUN curl -fsSL https://raw.githubusercontent.com/ros/rosdistro/master/ros.key -o /usr/share/keyrings/ros.key && \
    curl -fsSL $APT_REPOSITORY/movai-applications/gpg | apt-key add - && \
    curl -s https://raw.githubusercontent.com/ros/rosdistro/master/ros.asc | apt-key add - && \
    echo "deb http://packages.ros.org/ros/ubuntu focal main" > /etc/apt/sources.list.d/ros-latest.list && \
    add-apt-repository "deb [arch=all] $APT_REPOSITORY/ppa-public main main" && \
    # Add our pip repos
    setup-pypi-env.sh INT \
    # enable-custom-rosdep.sh - Create local registry for debian building (temporary. To be moved to ros-buildtools) and Install required packages
    /usr/local/bin/enable-custom-rosdep.sh PROD && \
    # Install required packages
    apt-get install python3-pip --reinstall -y && \
    /usr/local/bin/install-packages.sh && \
    mkdir -p /opt/mov.ai/docs && \
    chown -R movai:movai /opt/mov.ai/docs && \
    # Setup ROS environment
    echo "source /opt/ros/humble/setup.bash" >> /etc/bash.bashrc && \
    # Install ros1_bridge from tarball
    mkdir -p /ros2_ws/ros-humble-ros1-bridge && \
    tar xzf /ros2_ws/ros-humble-ros1-bridge.tgz -C /ros2_ws/ros-humble-ros1-bridge --strip-components=1 && \
    rm /ros2_ws/ros-humble-ros1-bridge.tgz && \
    # Source the ros1_bridge setup script in bashrc
    echo "source /ros2_ws/ros-humble-ros1-bridge/install/local_setup.bash" >> /etc/bash.bashrc && \
    # Clean apt
    apt-get autoremove -y && \
    apt-get clean -y > /dev/null && \
    rm -rf /var/cache/apt/* && \
    rm -rf /var/lib/apt/lists/* && \
    # Clean temp files
    rm -rf /tmp/*

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

ENV IGNITION_VERSION=garden

SHELL ["/bin/bash", "-e", "-o", "pipefail", "-c"]
# hadolint ignore=DL3004
RUN curl -fsSL http://packages.osrfoundation.org/gazebo.key | sudo apt-key add - && \
    sudo add-apt-repository "deb http://packages.osrfoundation.org/gazebo/ubuntu-stable $(lsb_release -cs) main" && \
    sudo apt-get install -y --no-install-recommends \
        ignition-garden \
        ignition-gazebo7 \
        ros-humble-ros-ign-gazebo \
        ros-humble-ros-ign-bridge \
        ros-humble-ros-ign-image && \
    sudo apt-get clean -y > /dev/null && \
    rm -rf /opt/mov.ai/user/cache/
