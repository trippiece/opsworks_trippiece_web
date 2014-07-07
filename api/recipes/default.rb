package 'git' do
  action :install
end

%w{python27 python27-devel python-pip}.each do |pkg|
  package pkg do
    action :upgrade
  end
end

include_recipe 'python::virtualenv'

directory node[:virtualenv][:parent] do
  owner node[:app][:owner]
  group node[:app][:group]
  mode 0755
  action :create
end

python_virtualenv node[:virtualenv][:path] do
  owner node[:app][:owner]
  group node[:app][:group]
  interpreter "python27"
  action :create
end


%w{mysql mysql-devel}.each do |pkg|
  package pkg do
    action :upgrade
  end
end


directory node[:app][:directory] do
  owner node[:app][:owner]
  group node[:app][:group]
  mode 0755
  action :create
end

git "#{node[:app][:directory]}/#{node[:app][:host]}" do
  repository node[:app][:repository]
  revision "master"
  action :sync
  user node[:app][:owner]
  group node[:app][:group]
end


include_recipe 'gunicorn'
gunicorn_config "/etc/gunicorn/#{node[:app][:name]}.py" do
  listen '127.0.0.1:8000'
  worker_processes (node['cpu'] && node['cpu']['total']) && [node['cpu']['total'].to_i * 2 + 1, 8].min || 5
  action :create
end


include_recipe 'supervisor'
supervisor_service "gunicorn-#{node[:app][:name]}" do
  command "#{::File.join(node[:virtualenv][:path], 'bin', 'gunicorn')} #{node[:app][:wsgi]}"
  autostart true
  autorestart true
  user node[:app][:owner]
  directory "#{node[:app][:directory]}/#{node[:app][:host]}/#{node[:app][:name]}"
end


include_recipe 'nginx'
nginx_web_app node[:app][:host] do
  cookbook 'nginx'
end

include_recipe 'chef-td-agent'
