#!/bin/bash
# File: movai-entrypoint.sh
set -e
printf "Mov.ai Spawner - %s Edition\n" "$MOVAI_ENV"

# Include ROS main workspace
source "/opt/ros/${ROS_DISTRO}/setup.bash"

# Include ROS workspace vars
if [ -f ${ROS1_USER_WS}/setup.bash ]; then
    source ${ROS1_USER_WS}/setup.bash
fi

if [ "$MOVAI_ENV" = "develop" ]; then
    MOVAI_PPA="dev"
    if [ ! -f "${MOVAI_HOME}/.first_run" ]; then
        /usr/local/bin/deploy.sh && touch "${MOVAI_HOME}/.first_run"
    fi
elif [ "$MOVAI_ENV" = "qa" ]; then
    MOVAI_PPA="testing"
else
    MOVAI_PPA="main"
fi

# Update ppa and spawner package
sudo add-apt-repository "deb [arch=all] https://artifacts.cloud.mov.ai/repository/ppa-$MOVAI_PPA $MOVAI_PPA main"
sudo apt-get update > /dev/null
sudo apt-get -y --no-install-recommends install movai-spawner --reinstall
sudo apt-get clean -y > /dev/null

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
if [ -f "${ROS1_USER_WS}/bin/startup.bash" ]; then
    "${ROS1_USER_WS}/bin/startup.bash"
fi

# Launch spawner init db tool
/usr/bin/python3 -m tools.init_local_db >/dev/null

"${APP_PATH}"/async_movaicore.py -v
