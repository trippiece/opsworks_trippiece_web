# pip install
bash "pip install dynamic-dynamodb" do
  user node[:app][:owner]
  group node[:app][:group]
  code <<-EOC
  export HOME=~#{node[:app][:owner]}
  #{node[:virtualenv][:path]}/bin/pip install dynamic-dynamodb==1.20.5
  EOC
end

config_path = "/etc/dynamic-dynamodb.conf"

template config_path do
  source 'dynamic-dynamodb.conf.erb'
  owner node[:app][:owner]
  group node[:app][:group]
  action :create
end

# supervisor config for dynamic-dynamodb
supervisor_service "dynamic-dynamodb" do
  command "#{::File.join(node[:virtualenv][:path], 'bin', 'dynamic-dynamodb')} -c #{config_path}"
  autostart true
  autorestart true
  startsecs 10
  user node[:app][:owner]
  stderr_logfile "#{node[:supervisor][:log_dir]}/dynamic-dynamodb-stderr.log"
end
