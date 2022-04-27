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

ROSDEP_YAML_PATH="/usr/local/rosdep"
ROSDEP_YAML_FILE="$ROSDEP_YAML_PATH/ros-pkgs.yaml"
GLOBAL_ROSDEP_SOURCELIST_FILE="/etc/ros/rosdep/sources.list.d/20-default.list"

mkdir -p "$ROSDEP_YAML_PATH"
touch $ROSDEP_YAML_FILE

chmod a+rw $ROSDEP_YAML_FILE
chmod a+rw $GLOBAL_ROSDEP_SOURCELIST_FILE
