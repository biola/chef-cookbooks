#
# Cookbook Name:: pbis-open
# Attributes:: default
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

default['pbis-open']['installation_script_url'] = "http://download.beyondtrust.com/PBISO/8.0.1/linux.deb.x64/pbis-open-8.0.1.2029.linux.x86_64.deb.sh"
default['pbis-open']['config_file'] = "/etc/pbis/pbis.conf"
default['pbis-open']['chef_vault'] = "ad_credentials"
default['pbis-open']['chef_vault_item'] = "pbis_bind"
default['pbis-open']['ad_domain'] = "corp.contoso.com"

default['pbis-open']['options']['LoginShellTemplate'] = '/bin/bash'