#
# Cookbook Name:: putty
# Recipe:: default
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

if node['platform'] == "windows" then

  if node['kernel']['machine'] == "x86_64" then

    include_recipe "windows::default"
  
    windows_package "PuTTY 0.62 x64" do
      source node['putty']['package_url']
      action :install
    end
  end
end
