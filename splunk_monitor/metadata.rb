maintainer       "Biola University"
maintainer_email "troy.ready@biola.edu"
license          "Apache 2.0"
description      "Encapsulates chef-splunk and chef-splunk-windows cookbooks; offers monitor configuration for Splunk forwarders"
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          "1.1.1"

%w{chef-splunk chef-splunk-windows chef-vault}.each do |d|
  depends d
end

%w{redhat centos fedora debian ubuntu windows}.each do |os|
  supports os
end
name	'splunk_monitor'
