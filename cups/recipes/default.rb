#
# Cookbook Name:: cups
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
#
package 'cups'

template '/etc/cups/cupsd.conf' do
  owner 'root'
  group 'lp'
  mode '0640'
end

service "cups" do
  supports :restart => true, :reload => true
  action :start
  subscribes :reload, "template[/etc/cups/cupsd.conf]"
end

lpstatcmd = Mixlib::ShellOut.new("lpstat -v")
lpstatcmd.run_command
printers = lpstatcmd.stdout.split(/\n/)
printers.map! do |x|
  phash = {}
  phash['name'] = x.gsub(/^device\sfor\s/,'').gsub(/:\s.*/,'')
  phash['uri'] = x.gsub(/^.*:\s/,'')
  phash
end

oldprinters = []

printers.each do |px|
  oldprinters << px['name']
end

node['cups']['printers'].each do |newprinter|
  # newprinter.first[0] is the printer name
  cmdline = "lpadmin -p #{newprinter.first[0]} -E -v #{newprinter.first[1]['uri']}"
  if newprinter.first[1]['model']
    cmdline << " -m #{newprinter.first[1]['model']}"
  else
    cmdline << " -m textonly.ppd"
  end
  if newprinter.first[1]['location']
    cmdline << " -L \"#{newprinter.first[1]['location']}\""
  end
  if newprinter.first[1]['desc']
    cmdline << " -D \"#{newprinter.first[1]['desc']}\""
  end
  unless oldprinters.include?(newprinter.first[0])
    execute cmdline
  else
    printers.each do |oldprinterhash|
      if oldprinterhash['name'] == newprinter.first[0]
        unless oldprinterhash['uri'] == newprinter.first[1]['uri']
          execute cmdline
        end
      end
    end
  end
end
