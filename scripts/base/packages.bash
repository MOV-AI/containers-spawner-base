#!/bin/bash
#
# Copyright 2021 MOV.AI
#
#    Licensed under the Mov.AI License version 1.0;
#    you may not use this file except in compliance with the License.
#    You may obtain a copy of the License at
#
#        https://www.mov.ai/flow-license/
#
#    Unless required by applicable law or agreed to in writing, software
#    distributed under the License is distributed on an "AS IS" BASIS,
#    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#    See the License for the specific language governing permissions and
#    limitations under the License.
#
# Add user to sudoers

SUDO_COMMANDS=(
    ${APP_PATH}/async_movaicore.py
    /usr/bin/dpkg
    /usr/bin/make
    /usr/bin/bluetoothctl
    /usr/bin/python3
    /usr/bin/rosdep
    /usr/bin/mobros
)

# Setup available sudo commands for user movai
[ -f /etc/sudoers.d/movai ] || touch /etc/sudoers.d/movai

for SUDO_COMMAND in ${SUDO_COMMANDS[@]}; do
    echo "%sudo ALL=(ALL) NOPASSWD:SETENV: ${SUDO_COMMAND}" >> /etc/sudoers.d/movai
done

{
    echo 'Defaults  env_keep += "ROS_DISTRO"'
    echo 'Defaults  env_keep += "MOVAI_ENV"'
    echo 'Defaults  env_keep += "MOVAI_HOME"'
    echo 'Defaults  env_keep += "PYTHON_VERSION"'
    echo 'Defaults  env_keep += "ROS1_MOVAI_WS"'
    echo 'Defaults  env_keep += "ROS2_MOVAI_WS"'
    echo 'Defaults  env_keep += "ROS1_USER_WS"'
    echo 'Defaults  env_keep += "ROS2_USER_WS"'
    echo 'Defaults  env_keep += "MOVAI_USERSPACE"'
} >> /etc/sudoers.d/movai


# Run movai-ros-provision as movai user
sudo -i -u movai /tmp/movai-ros-provision.sh

# fix permission
chown movai:movai -R ${MOVAI_HOME}

{
    echo "Package: *" 
    echo "Pin: origin artifacts.cloud.mov.ai"
    echo "Pin-Priority: 1001" 
} >> /etc/apt/preferences.d/movai

{
    echo "Package: *"
    echo "Pin: origin artifacts.aws.cloud.mov.ai"
    echo "Pin-Priority: 1001"
}  >> /etc/apt/preferences.d/movai-ros
