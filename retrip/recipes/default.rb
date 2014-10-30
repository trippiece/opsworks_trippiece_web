include_recipe 'common::virtualenv'

# install python and other required packages.
%w{mysql mysql-devel libmemcached libmemcached-devel npm libjpeg-devel}.each do |pkg|
  package pkg do
    action :upgrade
  end
end

# install grunt-cli
bash 'npm install -g grunt-cli' do
  code <<-EOC
  npm install -g grunt-cli
  EOC
end

include_recipe 'common::postfix'

include_recipe 'common::repository'

app_directory = "#{node[:app][:directory]}/#{node[:app][:host]}"

# place credential files.
template "#{app_directory}/#{node[:app][:name]}/#{node[:app][:name]}/settings/settings_base_credential.py" do
  source 'settings_base_credential.py.erb'
  owner node[:app][:owner]
  group node[:app][:group]
  action :create
end

template "#{app_directory}/#{node[:app][:name]}/#{node[:app][:name]}/settings/#{node[:app][:credential]}" do
  source 'settings_env_credential.py.erb'
  owner node[:app][:owner]
  group node[:app][:group]
  action :create
end

# supervisor must be called before gunicorn and celeryd.
include_recipe 'supervisor'

include_recipe 'common::gunicorn'

include_recipe 'nginx'
nginx_web_app node[:app][:host] do
  cookbook 'retrip'
end

include_recipe 'common::td-agent'
# configuration
template "/etc/td-agent/td-agent.conf" do
  source 'td-agent.conf.erb'
  action :create
  # no need to notify since the template is subscribed.
end
