#
# Cookbook Name:: opsview
# Recipe:: core
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

::Chef::Recipe.send(:include, Opscode::OpenSSL::Password)

include_recipe "opsview::apt_repository"
include_recipe "mysql::server"

# Install extra packages
node['opsview']['extra_packages'].each do |p|
  package p
end

# Service definitions
service "opsview" do
  action :nothing
end
service "opsview-web" do
  action :nothing
end
service "apache2" do
  action :nothing
end

# Set up the nagios user and groups
user "nagios" do
  group "nagios"
  home node['opsview']['nagios_user_home']
  shell "/bin/bash"
  system true
  supports :manage_home=>true
end
group "nagcmd" do
  members "nagios"
end
directory node['opsview']['nagios_user_home'] do
  owner "nagios"
  group "nagios"
  mode 0700
end

# Retrieve the mysql root password
root_password = nil
# Get the password from a data bag item
if !node['mysql']['users_databag'].nil?
  if !node['mysql']['databag_encryption_key'].nil?
    encryption_key = Chef::EncryptedDataBagItem.load_secret("#{node['mysql']['databag_encryption_key']}")
    root_password = Chef::EncryptedDataBagItem.load(node['mysql']['users_databag'], 'root', encryption_key)['password']
  else
    root_password = data_bag_item(node['mysql']['users_databag'], 'root')['password']
  end
# Or get the password from an attribute
else
  root_password = node['mysql']['server_root_password']
end

# Prepare a debconf seed for the opsview package
execute "preseed opsview" do
  command "debconf-set-selections /var/cache/local/preseeding/opsview.seed"
  action  :nothing
end

template "/var/cache/local/preseeding/opsview.seed" do
  source "opsview.seed.erb"
  mode 0600
  action :create
  variables(
    :root_password => root_password
  )
  notifies :run, "execute[preseed opsview]", :immediately
end

# Install the opsview package
package "opsview"

# Set the authtkt shared secret
node.set['opsview']['shared_secret'] = secure_password unless node['opsview']['shared_secret']
execute "set shared secret" do
  command "sed -i 's/1;/$authtkt_shared_secret = \"#{node['opsview']['shared_secret']}\";\\n1;/' /usr/local/nagios/etc/opsview.conf"
  action :run
  not_if "grep -r '$authtkt_shared_secret' /usr/local/nagios/etc/opsview.conf"
  notifies :restart, resources(:service => "opsview-web"), :immediately
end

# Enable SSL if configured
if node['opsview']['use_ssl']
  execute "enable ssl" do
    command "sed -i 's/1;/$use_https = 1;\\n1;/' /usr/local/nagios/etc/opsview.conf"
    action :run
    not_if "grep -r '$use_https' /usr/local/nagios/etc/opsview.conf"
    notifies :restart, resources(:service => "opsview-web"), :immediately
  end
end

# Set up Apache
package "libapache2-mod-proxy-html"
template "/etc/apache2/sites-available/opsview" do
  source "apache-opsview.erb"
  mode 0644
  action :create
  variables(
    :shared_secret => node['opsview']['shared_secret']
  )
  notifies :run, "execute[enable apache site]", :immediately
end

execute "enable apache site" do
  command "a2ensite opsview; a2dissite default; a2enmod proxy; a2enmod ssl; a2enmod proxy_http; a2enmod proxy_html"
  action :nothing
  notifies :restart, resources(:service => "apache2"), :immediately
end

# Create a directory to store JSON configuration
directory node['opsview']['json_config_dir'] do
  owner "nagios"
  group "nagios"
  mode 0700
end

# Update the Opsview admin password
node.set['opsview']['admin_password'] = "initial" unless node['opsview']['admin_password']
admin_password = data_bag_item(node['opsview']['contacts_databag'], 'admin')['password']
admin_encrypted_password = data_bag_item(node['opsview']['contacts_databag'], 'admin')['encrypted_password']

unless node['opsview']['admin_password'] == admin_password
  template "#{node['opsview']['json_config_dir']}/admin.json" do
    source "admin.json.erb"
    mode 0644
    variables(:encrypted_password => admin_encrypted_password)
    notifies :run, "execute[update admin password]", :immediately
  end

  execute "update admin password" do
    command "#{node['opsview']['opsview_rest_path']}  --username=admin --password=#{node['opsview']['admin_password']} --content-file=#{node['opsview']['json_config_dir']}/admin.json --data-format=json --pretty PUT config/contact"
    action :nothing
  end

  node.set['opsview']['admin_password'] = admin_password
end

# Install custom icons
directory node['opsview']['icons_dir'] do
  owner "nagios"
  group "nagios"
  mode 0700
end

cb = run_context.cookbook_collection[cookbook_name]
cb.manifest['files'].each do |cbfile|
  if cbfile['path'] =~ /icons/
    filename = cbfile['name'].sub(/^icons\//,'')
    cookbook_file "#{node['opsview']['icons_dir']}/#{filename}" do
      source "icons/#{cbfile['name']}"
      notifies :run, "execute[create host icon for #{filename}]", :immediately
    end

    execute "create host icon for #{filename}" do
      command "/usr/local/nagios/bin/hosticon_admin add '#{filename.sub(/.png$/,'')}' #{node['opsview']['icons_dir']}/#{filename}"
      action :nothing
    end
  end
end

# Install custom server plugins
remote_directory node['opsview']['plugin_dir'] do
  source "server_plugins"
  files_owner "nagios"
  files_group "nagios"
  files_mode 00755
  notifies :run, "execute[reload opsview config]", :immediately
end

# Install custom server event handlers
remote_directory "#{node['opsview']['plugin_dir']}/eventhandlers" do
  source "eventhandlers"
  files_owner "nagios"
  files_group "nagios"
  files_mode 00755
end

# Search for nodes to monitor
Chef::Log.info('Searching for nodes to monitor...')
nodes = []

if node["opsview"].attribute?("environments")
  nodes = search(:node, "(chef_environment:#{node['opsview']['environments'].join(" OR chef_environment:")}) NOT name:#{node.name}")
else
  nodes = search(:node, "chef_environment:#{node.chef_environment} NOT name:#{node.name}")
end
nodes.sort! { |a, b| a.name <=> b.name }

# Retrieve configuration from data bags
opsview_databags = OpsviewDataBags.new
objects = {}

# Object types must be created in order
objects['attribute'] = opsview_databags.get(node['opsview']['attributes_databag'])
objects['keyword'] = opsview_databags.get(node['opsview']['keywords_databag'])
objects['servicegroup'] = opsview_databags.get(node['opsview']['servicegroups_databag'])
objects['hosttemplate'] = opsview_databags.get(node['opsview']['hosttemplates_databag'])
objects['hostgroup'] = opsview_databags.get(node['opsview']['hostgroups_databag'])
objects['sharednotificationprofile'] = opsview_databags.get(node['opsview']['sharednotificationprofiles_databag'])
objects['role'] = opsview_databags.get(node['opsview']['roles_databag'])
objects['contact'] = opsview_databags.get(node['opsview']['contacts_databag'])
objects['timeperiod'] = opsview_databags.get(node['opsview']['timeperiods_databag'])
objects['host'] = nodes
objects['unmanagedhost'] = opsview_databags.get(node['opsview']['unmanagedhosts_databag'])
objects['servicecheck'] = opsview_databags.get(node['opsview']['servicechecks_databag'])

# Write the configuration to JSON and update through the API
objects.each do |object_type, values|
  values.sort! {|a,b| a["name"] <=> b["name"] }

  # Compare the values to the existing JSON and look for deleted objects
  if File.exists?("#{node['opsview']['json_config_dir']}/#{object_type}.json")
    existing_json = JSON.parse(File.open("#{node['opsview']['json_config_dir']}/#{object_type}.json").read, :create_additions => false)

    # Get arrays of object names
    existing_objects = existing_json["list"].collect { |e| e['name'] }
    chef_objects = (object_type == 'host') ? values.collect { |c| c.name } : values.collect { |c| c['name'] }

    # Get an array of object names that no longer exist in Chef
    deleted_objects = existing_objects - chef_objects

    # Make sure we don't delete everything
    if (!deleted_objects.nil? && (deleted_objects.count != values.count))
      deleted_objects.each do |object_name|
        # Get the object ID
        object_info = nil
        if object_type == 'unmanagedhost'
          object_info = JSON.parse(`#{node['opsview']['opsview_rest_path']} --username=admin --password=#{admin_password} --data-format=json --pretty GET 'config/host?json_filter={"name":"#{object_name}"}'`)
        else
          object_info = JSON.parse(`#{node['opsview']['opsview_rest_path']} --username=admin --password=#{admin_password} --data-format=json --pretty GET 'config/#{object_type}?json_filter={"name":"#{object_name}"}'`)
        end

        # Delete the object
        unless ((object_type == 'contact') && (object_name == 'admin'))
          unless object_info["list"].empty?
            Chef::Log.info("Deleting #{object_name}...")
            execute "delete #{object_name}" do
              if object_type == 'unmanagedhost'
                command "#{node['opsview']['opsview_rest_path']} --username=admin --password=#{admin_password} DELETE config/host/#{object_info["list"].first["id"]}"
              else
                command "#{node['opsview']['opsview_rest_path']} --username=admin --password=#{admin_password} DELETE config/#{object_type}/#{object_info["list"].first["id"]}"
              end
              notifies :run, "execute[reload opsview config]", :delayed
              action :run
            end
          end
        end
      end
    end
  end

  template "#{node['opsview']['json_config_dir']}/#{object_type}.json" do
    source "#{object_type}.json.erb"
    mode 0644
    variables(:values => values)
    notifies :run, "execute[put #{object_type}]", :immediately
    notifies :run, "execute[reload opsview config]", :delayed
  end

  execute "put #{object_type}" do
    if object_type == 'unmanagedhost'
      command "#{node['opsview']['opsview_rest_path']} --username=admin --password=#{admin_password} --content-file=#{node['opsview']['json_config_dir']}/#{object_type}.json --data-format=json --pretty PUT config/host"
    else
      command "#{node['opsview']['opsview_rest_path']} --username=admin --password=#{admin_password} --content-file=#{node['opsview']['json_config_dir']}/#{object_type}.json --data-format=json --pretty PUT config/#{object_type}"
    end
    action :nothing
  end
end

# Reload the Opsview config
execute "reload opsview config" do
  command "#{node['opsview']['opsview_rest_path']} --username=admin --password=#{admin_password} POST reload"
  action :nothing
end