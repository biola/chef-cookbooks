#
# Cookbook Name:: opsview
# Recipe:: check_mongodb
#
# Copyright 2014, Biola University
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

# Install Python module for MongoDB
package "python-pymongo"

# Download check_mongodb.py plugin
remote_file "/usr/local/nagios/libexec/check_mongodb.py" do
  source node['opsview']['check_mongodb']['plugin_url']
  owner "root"
  group "root"
  mode "0755"
  action :create_if_missing
end