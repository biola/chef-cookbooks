#
# Cookbook Name:: opsview
# Recipe:: check_mysql
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

# Install DBD::MySQL Perl module
package "libdbd-mysql-perl"

# Build and install the check_mysql_health plugin
remote_file "#{Chef::Config[:file_cache_path]}/check_mysql_health-#{node['opsview']['check_mysql']['plugin_version']}.tar.gz" do
  source node['opsview']['check_mysql']['plugin_url']
  checksum node['opsview']['check_mysql']['plugin_checksum']
  action :create_if_missing
end

bash 'build-check-mysql' do
  cwd Chef::Config[:file_cache_path]
  code <<-EOH
    tar zxvf check_mysql_health-#{node['opsview']['check_mysql']['plugin_version']}.tar.gz
    cd check_mysql_health-#{node['opsview']['check_mysql']['plugin_version']}
    ./configure --prefix=/usr/local/nagios \
      --with-nagios-user=nagios \
      --with-nagios-group=nagios \
      --with-perl=/usr/bin/perl \
      --with-statefiles-dir=#{node['opsview']['check_mysql']['statefiles_dir']}
    make
    make install
  EOH
  creates '/usr/local/nagios/libexec/check_mysql_health'
end