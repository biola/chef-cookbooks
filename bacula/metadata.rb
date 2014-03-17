name             'bacula'
maintainer       'Biola University'
maintainer_email 'troy.ready@biola.edu'
license          'Apache 2.0'
description      'Installs/Configures bacula'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          '0.3.1'
supports         'ubuntu'
supports         'redhat'
supports         'centos'
supports         'windows'
depends          'mysql'
depends          'database'
depends          'openssl'
depends          'chef-vault'