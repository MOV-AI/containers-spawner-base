#!/usr/bin/python3
# -*- coding: utf-8 -*-
"""

    Copyright 2021 MOV.AI

    Licensed under the Mov.AI License version 1.0;
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

        https://www.mov.ai/flow-license/

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

    This is the GD_Node

"""
import argparse
from gd_node.node import GDNode

if __name__ == '__main__':

    parser = argparse.ArgumentParser(description="Launch GD_Node")
    parser.add_argument("-n", "--name", help="GD_Node template name",
                        type=str, required=True, metavar='')
    parser.add_argument("-i", "--inst", help="GD_Node instance name",
                        type=str, required=True, metavar='')
    parser.add_argument(
        "-p", "--params", help="GD_Node instance parameters \"param_name:=param_value,...\"", type=str, metavar='')
    parser.add_argument(
        "-f", "--flow", help="Flow name where GD_Node is running", type=str, metavar='')
    parser.add_argument("-v", "--verbose",
                        help="Increase output verbosity", action="store_true")
    parser.add_argument("-m", "--message",
                        help="Message to pass to state", type=str, metavar='')
    parser.add_argument(
        "-d", "--develop", help="Development mode enables real-time callback update", action="store_true")

    ARGS, UNKNOWN = parser.parse_known_args()

    GDNode(ARGS, UNKNOWN)