#!/bin/bash
# Copyright 2013 Google Inc. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Begin: edit these values to set up your cluster
# GCS bucket for packages
readonly GCS_PACKAGE_BUCKET={{{{ bucket_name }}}}
# Zone of the Hadoop master instance
readonly ZONE={{{{ zone_id }}}}
# Hadoop master instance name
readonly MASTER={{{{ master_hostname }}}}

# Set to the major version of hadoop ("1" or "2")
readonly HADOOP_MAJOR_VERSION="1"

# Hadoop username and group on Compute Engine Cluster
readonly HADOOP_USER=hadoop
readonly HADOOP_GROUP=hadoop

# Hadoop client username on Compute Engine Cluster
readonly HDP_USER=hdpuser

# Directory on master where hadoop is installed
readonly HADOOP_HOME=/home/hadoop/hadoop

# Directory on master where packages are installed
readonly HDP_USER_HOME=/home/hdpuser
readonly MASTER_INSTALL_DIR=/home/hdpuser

# Directory on master where Java is installed
readonly JAVA_HOME=/usr/lib/jvm/java-6-openjdk-amd64

# End: edit these values to set up your cluster


# Begin: constants used througout the solution

# Subdirectory where packages files (tar.gz) are stored
readonly PACKAGES_DIR=packages

# Subdirectory where scripts are stored
readonly SCRIPTS_DIR=scripts

# Subdirectory in cloud storage where packages are pushed at initial setup
readonly GCS_PACKAGE_DIR=hdp_tools

# Subdirectory on master where we pull down package files
readonly MASTER_PACKAGE_DIR=/tmp/hdp_tools

# End: constants used througout the solution
