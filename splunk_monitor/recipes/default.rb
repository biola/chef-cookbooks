#
# Cookbook Name:: splunk_monitor
# Recipe:: default
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

# Install chef-rewind gem
chef_gem "chef-rewind"
require 'chef/rewind'

include_recipe 'chef-vault'
splunk_auth_info = chef_vault_item(:vault, "splunk_#{node.chef_environment}")['auth']

# Service name will depend on the OS
case node['os']
when "windows"
  servicename = "SplunkForwarder"
when "linux"
  servicename = "splunk"
end

service servicename do
  supports :restart => true
  action :nothing
end

# Override download URL
download_path = "#{node['splunk']['forwarder']['version']}/universalforwarder/#{node['os']}/splunkforwarder-#{node['splunk']['forwarder']['version']}-#{node['splunk']['forwarder']['build']}" + 
  case node['platform']
  when "centos","redhat","fedora"
    if node['kernel']['machine'] == "x86_64"
      "-linux-2.6-x86_64.rpm"
    else
      ".i386.rpm"
    end
  when "debian","ubuntu"
    if node['kernel']['machine'] == "x86_64"
      "-linux-2.6-amd64.deb"
    else
      "-linux-2.6-intel.deb"
    end
  when "windows"
    if node['kernel']['machine'] == "x86_64"
      "-x64-release.msi"
    else
      "-x86-release.msi"
    end
  end
node.default['splunk']['forwarder']['url'] = "#{node['splunk']['forwarder']['base_url']}/#{download_path}"

# Override search for Splunk servers to exclude the environment
splunk_servers = search(
  :node,
  "splunk_is_server:true"
).sort! do
  |a, b| a.name <=> b.name
end

case node['os']
when "linux"
  include_recipe "chef-splunk::install_forwarder"

  directory "/opt/splunkforwarder/etc/system/local" do
    recursive true
    owner 'root'
    group 'root'
  end

  template "/opt/splunkforwarder/etc/system/local/outputs.conf" do
    source 'outputs.conf.erb'
    cookbook 'chef-splunk'
    mode 0644
    variables :splunk_servers => splunk_servers, :outputs_conf => node['splunk']['outputs_conf']
    notifies :restart, 'service[splunk]'
  end
  
  # Accept license when upgrading Splunk
  execute "#{splunk_cmd} enable boot-start --accept-license --answer-yes && echo true > /opt/splunk_license_accepted_#{node['splunk']['forwarder']['version']}" do
    not_if { ::File.exist?("/opt/splunk_license_accepted_#{node['splunk']['forwarder']['version']}") }
    notifies :start, 'service[splunk]'
  end

  include_recipe 'chef-splunk::setup_auth'
when "windows"
  include_recipe "chef-splunk-windows::default"
  include_recipe "chef-splunk-windows::windows_ta"

  rewind "template[#{node['splunk']['forwarder']['home']}/etc/system/local/outputs.conf]" do
    variables :splunk_servers => splunk_servers
  end
end

# To avoid confusion between systems with the same hostname, add the subdomain if configured
case node['splunk']['hostname_source']
when "hostname_with_subdomain"
  splunk_hostname = node['fqdn'].gsub(/\.\w*\.\w*$/, '')
when "node_name"
  splunk_hostname = node.name
else
  splunk_hostname = node['hostname']
end

# Save the hostname in the node's attributes
node.set['splunk']['hostname'] = splunk_hostname

# Update splunk default hostname in system inputs.conf
template "#{node['splunk']['forwarder']['home']}/etc/system/local/inputs.conf" do
  source "system-inputs.conf.erb"
  if node["os"] == "linux"
    owner "root"
    group "root"
    mode "0600"
  end
  variables({
    :splunk_hostname => splunk_hostname
  })
  notifies :restart, resources(:service => servicename)
end

# Update splunk servername just before splunk is to be restarted
splunk_cmd = "#{node['splunk']['forwarder']['home']}/bin/splunk"
case node['os']
when "linux"
  execute "update_splunk_servername" do
    command "\"" + splunk_cmd + "\"" + " set servername "+ splunk_hostname + " -auth " + splunk_auth_info 
    subscribes :run, resources(:template => "#{node['splunk']['forwarder']['home']}/etc/system/local/inputs.conf"), :immediately
    action :nothing
  end
when "windows"
  windows_batch "update_splunk_servername" do
    code <<-EOH
    "#{splunk_cmd}" set servername #{splunk_hostname} -auth #{splunk_auth_info}
    EOH
    subscribes :run, resources(:template => "#{node['splunk']['forwarder']['home']}/etc/system/local/inputs.conf"), :immediately
    action :nothing
  end
end

if node['splunk']['monitors'] 
  directory "#{node['splunk']['forwarder']['home']}/etc/apps/search/local" do
    if node["os"] == "linux"
      owner "root"
      group "root"
    end
    action :create
  end
  template "#{node['splunk']['forwarder']['home']}/etc/apps/search/local/inputs.conf" do
    source "inputs.conf.erb"
    if node["os"] == "linux"
      owner "root"
      group "root"
      mode "0600"
    end
    variables ({
      :splunk_monitors => node['splunk']['monitors'],
      :splunk_scripts => node['splunk']['scripts'] 
    })
    notifies :restart, resources(:service => servicename)
  end
  # Now check and apply transforms as well
  if node['splunk']['transforms']
    directory "#{node['splunk']['forwarder']['home']}/etc/system/local" do
      if node["os"] == "linux"
        owner "root"
        group "root"
      end
      action :create
    end
    template "#{node['splunk']['forwarder']['home']}/etc/system/local/transforms.conf" do
      source "system-transforms.conf.erb"
      if node["os"] == "linux"
        owner "root"
        group "root"
        mode "0600"
      end
      variables ({
        :splunk_transforms => node['splunk']['transforms']
      })
      notifies :restart, resources(:service => servicename)
    end
    template "#{node['splunk']['forwarder']['home']}/etc/system/local/props.conf" do
      source "system-props.conf.erb"
      if node["os"] == "linux"
        owner "root"
        group "root"
        mode "0600"
      end
      variables ({
        :splunk_props => node['splunk']['props']
      })
      notifies :restart, resources(:service => servicename)
    end
  end
end
