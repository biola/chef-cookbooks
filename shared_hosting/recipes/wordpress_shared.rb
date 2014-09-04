#
# Cookbook Name:: shared_hosting
# Recipe:: wordpress_shared
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

# Install nginx and PHP
include_recipe "shared_hosting::default"
include_recipe "shared_hosting::nginx"
include_recipe "shared_hosting::php"

# Service definitions
service "nginx" do
  supports :restart => true, :reload => true
  action :nothing
end
service "php5-fpm" do
  supports :restart => true, :reload => true
  action :nothing
end

if node['shared_hosting']['wordpress_shared']['sites']
  # Create nginx configuration for php-fpm monitoring
  template "/etc/nginx/conf.d/php-status.inc" do
    owner "root"
    group "root"
    mode 00644
    source "php-status.inc.erb"
    variables(
      :sites => node['shared_hosting']['wordpress_shared']['sites']
    )
    notifies :reload, "service[nginx]"
  end

  # Set up each of the wordpress sites configured in node attributes
  node['shared_hosting']['wordpress_shared']['sites'].each do |site|
    site.each do |site_key, site_value|
      # Create a user account with a home folder in the wordpress sites directory
      account_name = site_value['user_name'].nil? ? site_key.to_s : site_value['user_name']
      user account_name do
        home "#{node['shared_hosting']['nginx']['sites_dir']}/#{site_key.to_s}"
        shell "/bin/bash"
        action :create
      end

      # Create the user's home directory with appropriate permissions
      directory "#{node['shared_hosting']['nginx']['sites_dir']}/#{site_key.to_s}" do
        unless site_value['chroot_user'] == false
          owner "root"
          group account_name
        else
          owner account_name
          group account_name
        end
        mode 00750
        action :create
      end

      # Add the account to the chrooted group if specified
      unless site_value['chroot_user'] == false
        group node['shared_hosting']['chroot_group'] do
          action :modify
          members account_name
          append true
        end
      end

      # Create a new php-fpm pool configuration for the site
      template "/etc/php5/fpm/pool.d/#{site_key.to_s}.conf" do
        owner "root"
        group "root"
        mode 00644
        source "php-fpm-pool.conf.erb"
        variables(
          :site_name => site_key.to_s,
          :user_name => account_name,
          :socket_dir => node['shared_hosting']['php']['socket_dir'],
          :sites_dir => node['shared_hosting']['nginx']['sites_dir'],
          :php_restrict_basedir => site_value['php_restrict_basedir'],
          :enable_mail => site_value['enable_mail'],
          :php_admin_flags => site_value['php_admin_flags'],
          :php_admin_values => site_value['php_admin_values']
        )
        notifies :restart, "service[php5-fpm]"
      end

      # Create a public_html directory inside the user's home
      directory "#{node['shared_hosting']['nginx']['sites_dir']}/#{site_key.to_s}/public_html" do
        owner account_name
        group account_name
        mode 00750
        action :create
      end
    end
  end

  # Create a new nginx shared site configuration
  nginx_template = node['shared_hosting']['wordpress_shared']['nginx_template'].nil? ? "wordpress-shared-site.erb" : node['shared_hosting']['wordpress_shared']['nginx_template']
  template "/etc/nginx/sites-available/wordpress_shared" do
    owner "root"
    group "root"
    mode 00644
    source nginx_template
    variables(
      :shared_sites => node['shared_hosting']['wordpress_shared']['sites'],
      :server_name => node['shared_hosting']['wordpress_shared']['server_name'],
      :include => node['shared_hosting']['wordpress_shared']['nginx_include']
    )
    notifies :reload, "service[nginx]"
  end

  # Enable the nginx site configuration
  link "/etc/nginx/sites-enabled/wordpress_shared" do
    to "/etc/nginx/sites-available/wordpress_shared"
    notifies :reload, "service[nginx]"
  end
end