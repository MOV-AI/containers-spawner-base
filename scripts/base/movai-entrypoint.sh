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
# File: movai-entrypoint.sh
set -e
printf "Mov.ai Spawner - %s Edition\n" "$MOVAI_ENV"

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
    mkdir -p "${MOVAI_USERSPACE}/{bags,cache,database}"
else
    echo "No userspace detected"
fi

# If we have a startup.bash we run it
if [ -f "${ROS1_USER_WS}/bin/startup.bash" ]; then
    "${ROS1_USER_WS}/bin/startup.bash"
fi

# Launch spawner init db tool
echo "Info : initializing local DB ..."
init_local_db >/dev/null &
echo "Info : initializing local DB. DONE"

# First run metadata initializations
if [ ! -f "${MOVAI_HOME}/.first_run_metadata" ] && [ "$UPDATE_MASTER_METADATA" = "true" ]; then
    touch "${MOVAI_HOME}/.first_run_metadata"

    # this require to be installing on a running MOVAI spawner container
    MOVAI_PACKAGES_PATH="/opt/ros/$ROS_DISTRO/share"
    MOVAI_BACKUP_TOOL_PATH="/opt/mov.ai/app"
    if [ -d "$MOVAI_BACKUP_TOOL_PATH/tools" ]; then
        echo "Info : initializing local DB with local packages metadata"
    else
        echo "Warning : local DB initializer not found"
    fi

    pushd "$MOVAI_BACKUP_TOOL_PATH" > /dev/null
    find "${MOVAI_PACKAGES_PATH}" -maxdepth 2 -type d -name "metadata" -print0 | while read -d $'\0' PACKAGE_PATH
    do
        echo "Info : initializing local DB with $PACKAGE_PATH"
        PACKAGE_BASE_PATH=$(dirname "$PACKAGE_PATH")
        dal_backup -f -i -a import -m "$PACKAGE_BASE_PATH/manifest.txt" -r "$PACKAGE_BASE_PATH" -p "$PACKAGE_BASE_PATH/metadata"
    done
    popd > /dev/null
fi

flow_initiator
