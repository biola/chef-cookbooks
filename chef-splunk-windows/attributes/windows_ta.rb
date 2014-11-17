#
# Cookbook Name:: chef-splunk-windows
# Attributes:: windows_ta
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

# A path to the Windows TA file must be provided; the file must be in zip format
default['splunk']['windows_ta']['url'] = 'http://download.contoso.com/splunk/splunk-add-on-for-microsoft-windows_470.zip'

# OS Logs
default['splunk']['windows_ta']['application_log'] = {
  "disabled" => "1",
  "checkpointInterval" => "5",
  "index" => "winevents"
}
default['splunk']['windows_ta']['security_log'] = {
  "disabled" => "1",
  "checkpointInterval" => "5",
  "index" => "winevents"
}
default['splunk']['windows_ta']['system_log'] = {
  "disabled" => "1",
  "checkpointInterval" => "5",
  "index" => "winevents"
}

# Windows Update Log
default['splunk']['windows_ta']['windowsupdate_log'] = {
  "disabled" => "1",
  "index" => "windows"
}

# Performance Counters
default['splunk']['windows_ta']['perfmon_cpu'] = {
  "disabled" => "1",
  "interval" => "10",
  "index" => "perfmon"
}
default['splunk']['windows_ta']['perfmon_memory'] = {
  "disabled" => "1",
  "interval" => "10",
  "index" => "perfmon"
}
default['splunk']['windows_ta']['perfmon_disk'] = {
  "disabled" => "1",
  "interval" => "3600",
  "index" => "perfmon"
}
default['splunk']['windows_ta']['perfmon_network'] = {
  "disabled" => "1",
  "interval" => "10",
  "index" => "perfmon"
}