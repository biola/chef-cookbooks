maintainer       "Biola University"
maintainer_email "jared.king@biola.edu"
license          "Apache 2.0"
description      "Manages MySQL databases, users, and backups using data bags and Opscode's database cookbook"
version          "2.2.1"
supports 				 "ubuntu", "12.04"
%w{ database mysql }.each do |cb|
  depends cb
end