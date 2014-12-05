#
# Cookbook Name:: cups
# Recipe:: airprint
#
# Copyright 2014, James Cuzella
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
#

Chef::Log.warn('Avahi will advertise AirPrint printers but cups will NOT share them and remote printing will not work unless you set node[\'cups\'][\'share_printers\']!!! Ensure that this is what you want!') unless node['cups']['share_printers']

package 'git'

if node['platform_family'] == 'rhel'
  package 'avahi'
  package 'python-lxml'
end

# Create cups mime type definition files
# Sources:  http://www.linux-magazine.com/Online/Features/AirPrint
#           http://confoundedtech.blogspot.com/2012/12/ios6-airprint-without-true-airprint.html
#           http://community.spiceworks.com/how_to/show/15491-print-to-ubuntu-12-04-shared-printer-via-windows-and-mac

[ 'types', 'convs' ].each do |mime_file_suffix|
  cookbook_file "airprint.#{mime_file_suffix}" do
    if node['platform_family'] == 'rhel'
      path "/etc/cups/airprint.#{mime_file_suffix}"
    else
      path "/usr/share/cups/mime/airprint.#{mime_file_suffix}"
    end
    owner 'root'
    group 'root'
    mode '0644'
    notifies :reload, 'service[cups]', :immediately
  end
end

# Ensure the python bindings for CUPS are installed
case node['platform_family']
when 'rhel'
  package 'system-config-printer-libs'
when 'debian'
  package 'python-cups'
end

# Generate Avahi AirPrint service definition XML files
#
# 1. Checkout airprint-generate.py git repo
# 2. Run airprint-generate.py script
# 3. Copy `.service` files to /etc/avahi/services/
git "#{Chef::Config[:file_cache_path]}/airprint-generate" do
  repository node['cups']['airprint']['airprint_generate']['git_url']
  revision node['cups']['airprint']['airprint_generate']['git_revision']
#  revision 'fb98c1ded7625b1b15cbbc0f9ac004a799c7c1a6' ## Latest as of 08/24/2014
  action :sync
end

execute 'generate_airprint_service_definitions' do
  cwd "#{Chef::Config[:file_cache_path]}/airprint-generate"
  if node['platform_family'] == 'debian'
    # sleep is necessary here to ensure cups reload is finished before execution during initial run
    command 'sleep 45 && python airprint-generate.py'
  else
    command 'python airprint-generate.py'
  end
  umask 0022 # Ensures any created files have correct permissions (666 - 022 = 644)
  user 'root'
  group 'root'
  returns 0
  notifies :run, 'bash[copy_airprint_service_definitions]'
end

bash 'copy_airprint_service_definitions' do
  cwd "#{Chef::Config[:file_cache_path]}/airprint-generate"
  code 'cp *.service /etc/avahi/services/'
  umask 0022
  user 'root'
  group 'root'
  returns 0
  action :nothing
  notifies :reload, 'service[avahi-daemon]', :immediately
end

# Reload cups service to pick up new mime types
service 'cups' do
  pattern 'cupsd'
  supports :restart => true, :reload => true, :status => true
  action :nothing
  # notified to reload by cookbook_file[airprint.*]
end

# Reload avahi-daemon to pick up new Airprint service definitions
service 'avahi-daemon' do
  supports :restart => true, :reload => true, :status => true
  action :nothing
end
