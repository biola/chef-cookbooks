#
# Cookbook Name:: opsview
# Attributes:: check_mysql
#
# Copyright 2014, Biola University
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE_2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

default['opsview']['check_mysql']['plugin_version'] = "2.1.8.2"
default['opsview']['check_mysql']['plugin_url'] = "http://labs.consol.de/download/shinken-nagios-plugins/check_mysql_health-2.1.8.2.tar.gz"
default['opsview']['check_mysql']['plugin_checksum'] = "7ae986ab7ecbb576dbb657e8ef0490f2"
default['opsview']['check_mysql']['statefiles_dir'] = "/tmp/check_mysql_health"