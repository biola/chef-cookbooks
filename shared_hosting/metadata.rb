maintainer       "Biola University"
maintainer_email "jared.king@biola.edu"
license          "Apache 2.0"
description      "Configures nodes for shared hosting environments"
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          "2.3.0"
supports         "ubuntu", "12.04"
%w{ apache2 database mysql nginx openssl pbis-open php }.each do |cb|
  depends cb
end