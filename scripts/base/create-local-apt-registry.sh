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
REGISTRY_PATH="/usr/local/apt-registry"

RELOAD_REGISTRY_SCRIPT_NAME="reload-local-debs.sh"
RELOAD_REGISTRY_SCRIPT_PATH="/usr/local/bin"

mkdir -p "${REGISTRY_PATH}" "${RELOAD_REGISTRY_SCRIPT_PATH}"

# Create script for local registry debian list reload
printf "\
    #! /bin/bash \n\
    cd ${REGISTRY_PATH} \n \
    dpkg-scanpackages . /dev/null | gzip -9c > Packages.gz " > "${RELOAD_REGISTRY_SCRIPT_PATH}/${RELOAD_REGISTRY_SCRIPT_NAME}"

chmod +x "${RELOAD_REGISTRY_SCRIPT_PATH}/${RELOAD_REGISTRY_SCRIPT_NAME}"
chown 1000 "${REGISTRY_PATH}"

# Run the Reload registry content script and make it avaiable for movai user
bash "${RELOAD_REGISTRY_SCRIPT_PATH}/${RELOAD_REGISTRY_SCRIPT_NAME}"
chown 1000:1000 "${REGISTRY_PATH}/Packages.gz"

# Have apt use our local registry
echo -e "deb [trusted=yes] file:${REGISTRY_PATH} ./ \n$(cat /etc/apt/sources.list)" > /etc/apt/sources.list

