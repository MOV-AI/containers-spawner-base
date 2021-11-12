#!/bin/bash
#
# Copyright 2019 Alexandre Pires (alexandre.pires@mov.ai)
#
#    Licensed under the Apache License, Version 2.0 (the "License");
#    you may not use this file except in compliance with the License.
#    You may obtain a copy of the License at
#
#        http://www.apache.org/licenses/LICENSE-2.0
#
#    Unless required by applicable law or agreed to in writing, software
#    distributed under the License is distributed on an "AS IS" BASIS,
#    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#    See the License for the specific language governing permissions and
#    limitations under the License.
#
# File: movai-entrypoint.sh
set -e
printf "Mov.ai Spawner - Production\n"

# Include ROS main workspace
source "/opt/ros/${ROS_DISTRO}/setup.bash"

# Include ROS workspace vars
if [ -f ${ROS1_USER_WS}/setup.bash ]; then
    source ${ROS1_USER_WS}/setup.bash
fi

export PATH=${MOVAI_HOME}/.local/bin:${PATH}
export PYTHONPATH=${APP_PATH}:${MOVAI_HOME}/sdk:${PYTHONPATH}

# if commands passed
[ $# -gt 0 ] && exec "$@"
# else

# If we have a userspace prepare it
if [ -d "${MOVAI_USERSPACE}" ]; then
    echo "Userspace detected"
    if ! [ -d "${MOVAI_USERSPACE}/bags" ]; then
        mkdir -p "${MOVAI_USERSPACE}/bags"
        echo "Created directory ${MOVAI_USERSPACE}/bags"
    fi
else
    echo "No userspace detected"
fi

# If we have a startup.bash we run it
if [ -f ${ROS1_USER_WS}/bin/startup.bash ]; then
    ${ROS1_USER_WS}/bin/startup.bash
fi

# Launch spawner init db tool
/usr/bin/python3 -m tools.init_local_db

# Running spawner as root, this should be reviewed in the future
${APP_PATH}/async_movaicore.py -v
