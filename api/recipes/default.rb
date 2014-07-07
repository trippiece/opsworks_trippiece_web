package 'git' do
  action :install
end

%w{python27 python27-devel python-pip}.each do |pkg|
  package pkg do
    action :upgrade
  end
end

include_recipe 'python::virtualenv'

directory node[:virtualenv][:location] do
  mode 0755
  action :create
end

virtualenv_path = "#{node[:virtualenv][:location]}/#{node[:app][:host]}"
python_virtualenv virtualenv_path do
  interpreter "python27"
  action :create
end


%w{mysql mysql-devel}.each do |pkg|
  package pkg do
    action :upgrade
  end
end


#include_recipe 'gunicorn'
application node[:app][:name] do
  path       "#{node[:app][:directory]}/#{node[:app][:host]}"
  owner      'ec2-user'
  group      'ec2-user'
  repository node[:app][:repository]
  revision   'master'
  migrate    true

  gunicorn do
    app_module node[:app][:wsgi]
    host node[:app][:host]
    port 8000
    workers (node['cpu'] && node['cpu']['total']) && [node['cpu']['total'].to_i * 2 + 1, 8].min || 5
    virtualenv virtualenv_path
    autostart true
    directory "#{node[:app][:directory]}/#{node[:app][:host]}/#{node[:app][:name]}"
  end

  celery do
    config "#{node[:app][:directory]}/#{node[:app][:host]}/#{node[:app][:name]}/#{node[:app][:name]}/#{node[:app][:settings]}"
  end
end


include_recipe 'nginx'
nginx_web_app node[:app][:host] do
  cookbook 'nginx'
end

include_recipe 'chef-td-agent'
