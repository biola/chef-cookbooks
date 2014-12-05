require 'serverspec'
# Set backend type
set :backend, :exec
# Don't include Specinfra::Helper::DetectOS

set :path, '/sbin:/usr/sbin:$PATH'

describe process("cupsd") do
  it { should be_running }
end

# Verify the printers are configured properly
describe command('lpstat -v') do
  its(:stdout) { should match /device for vagrantprinter1: lpd:\/\/192\.168\.10\.5\ndevice for vagrantprinter2: lpd:\/\/192\.168\.10\.6/ }
end
