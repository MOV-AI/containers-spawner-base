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

# First run apt initializations
if [ ! -f "${MOVAI_HOME}/.first_run_apt" ]; then
    touch "${MOVAI_HOME}/.first_run_apt"

    if [ "$MOVAI_ENV" = "develop" ]; then
        MOVAI_PPA="dev"
    elif [ "$MOVAI_ENV" = "qa" ]; then
        MOVAI_PPA="testing"
    else
        MOVAI_PPA="main"
    fi
    # Update ppa with correct env and make sure it is not cohabiting with another one
    for ppa_env in dev testing main; do
        # remove any old repo
        sudo add-apt-repository -r "deb https://artifacts.cloud.mov.ai/repository/ppa-${ppa_env} ${ppa_env} main"
    done || true

    # isnt this repeated with the previous iteration ?
    sudo add-apt-repository "deb [arch=all] https://artifacts.cloud.mov.ai/repository/ppa-$MOVAI_PPA $MOVAI_PPA main"

    # movai-spawner installing itself constantly is questionable
    # and its causing conflicts with movai-service commands on spawner to do apt related operations
    sudo apt-get -y --no-install-recommends install movai-spawner --reinstall

    if [ "$MOVAI_ENV" = "develop" ]; then
        /usr/local/bin/deploy.sh
    fi
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
if [ -f "${ROS1_USER_WS}/bin/startup.bash" ]; then
    "${ROS1_USER_WS}/bin/startup.bash"
fi

# Launch spawner init db tool
/usr/bin/python3 -m tools.init_local_db >/dev/null

# First run metadata initializations
if [ ! -f "${MOVAI_HOME}/.first_run_metadata" ]; then
    touch "${MOVAI_HOME}/.first_run_metadata"

    # this require to be installing on a running MOVAI spawner container
    MOVAI_PACKAGES_PATH="/opt/ros/$ROS_DISTRO/share"
    MOVAI_BACKUP_TOOL_PATH="/opt/mov.ai/app"
    if [ -d "$MOVAI_BACKUP_TOOL_PATH/tools" ]; then
        echo "Info : initializing local DB with local packages metadata"
    else
        echo "Warning : local DB initializer not found"
    fi

    find "${MOVAI_PACKAGES_PATH}" -maxdepth 2 -type d -name "metadata" -print0 | while read -d $'\0' PACKAGE_PATH
    do
        echo "Info : initializing local DB with $PACKAGE_PATH"
        PACKAGE_BASE_PATH=$(dirname "$PACKAGE_PATH")
        pushd "$PACKAGE_BASE_PATH" > /dev/null
        echo /usr/bin/python3 -m tools.backup -f -i -a import -m "$PACKAGE_BASE_PATH/manifest.txt" -r "$PACKAGE_BASE_PATH" -p "$PACKAGE_BASE_PATH/metadata"
        popd > /dev/null
    done

fi

"${APP_PATH}"/async_movaicore.py -v
