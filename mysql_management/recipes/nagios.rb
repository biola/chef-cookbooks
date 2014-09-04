#
# Cookbook Name:: mysql_management
# Recipe:: nagios
#
# Copyright 2013, Biola University
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

# Ensure that a data bag item for the Nagios MySQL user exists
user_exists = search(node['mysql']['management']['users_databag'], "id:#{node['mysql']['management']['nagios_user']}").first
if user_exists.nil?
	Chef::Log.warn "Unable to find a data bag item containing MySQL user information for Nagios. Skipping..."
else
	# Retrieve Nagios user information from the data bag containing MySQL user configuration
	encryption_key = Chef::EncryptedDataBagItem.load_secret(node['mysql']['management']['databag_encryption_key'])
	nagios_user = Chef::EncryptedDataBagItem.load(node['mysql']['management']['users_databag'], node['mysql']['management']['nagios_user'], encryption_key)

	# Create the configuration file for Nagios
  directory "/etc/nagios" do
    owner "nagios"
    group "nagios"
    mode "0755"
    action :create
  end  

  template node['mysql']['management']['nagios_conf_file'] do
    source "nagios.cnf.erb"
    mode 0600
    owner "nagios"
    group "nagios"
    variables(
    	:nagios_user_password => nagios_user['password']
    )
  end
end