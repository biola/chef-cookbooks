#
# Cookbook Name:: shared_hosting
# Attributes:: wordpress_shared
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

# Include the php-status.inc nginx configuration for the default site
if node.run_list.expand(node.chef_environment).recipes.include?("shared_hosting::wordpress_shared")
	default['shared_hosting']['nginx']['include'] << "php-status.inc"
end