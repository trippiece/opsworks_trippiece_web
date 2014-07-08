package 'git' do
  action :install
end


# python
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


# MySQL
%w{mysql mysql-devel}.each do |pkg|
  package pkg do
    action :upgrade
  end
end


# git clone
directory node[:app][:directory] do
  owner node[:app][:owner]
  group node[:app][:group]
  mode 0755
  action :create
end

ssh_known_hosts_entry 'github.com'

include_recipe 's3'
s3_file node[:sshkey][:path] do
  source node[:sshkey][:source]
  access_key_id node[:aws][:key]
  secret_access_key node[:aws][:secret]
  owner node[:app][:owner]
  group node[:app][:group]
  mode 0600
end

app_directory = "#{node[:app][:directory]}/#{node[:app][:host]}"
git app_directory do
  repository node[:app][:repository]
  revision "master"
  action :sync
  user node[:app][:owner]
  group node[:app][:group]
end


# pip install
bash "#{node[:virtualenv][:path]}/bin/pip install -r requirements.txt" do
  cwd app_directory
end


# celeryd
template node[:celery][:config] do
  source 'celeryd.erb'
  action :create
end


# gunicorn
include_recipe 'gunicorn'

gunicorn_config_path = "/etc/gunicorn/#{node[:app][:name]}.py"
gunicorn_config gunicorn_config_path do
  listen '127.0.0.1:8000'
  worker_processes (node['cpu'] && node['cpu']['total']) && [node['cpu']['total'].to_i * 2 + 1, 8].min || 5
  action :create
end


# supervisor
include_recipe 'supervisor'
# for gunicorn
supervisor_service "gunicorn-#{node[:app][:name]}" do
  command "#{::File.join(node[:virtualenv][:path], 'bin', 'gunicorn')} #{node[:app][:wsgi]} -c #{gunicorn_config_path}"
  autostart true
  autorestart true
  user node[:app][:owner]
  directory "#{app_directory}/#{node[:app][:name]}"
end
# for celeryd
supervisor_service "celeryd-#{node[:app][:name]}" do
  command "#{::File.join(node[:virtualenv][:path], 'bin', 'celery')} worker --config=#{node[:celery][:config]} -l info"
  autostart true
  autorestart true
  startsecs 10
  stopwaitsecs 600
  environment :DJANGO_SETTINGS_MODULE => "#{node[:app][:name]}.#{node[:app][:settings]}"
  user node[:app][:owner]
  directory "#{app_directory}/#{node[:app][:name]}"
end


# nginx
include_recipe 'nginx'
nginx_web_app node[:app][:host] do
  cookbook 'nginx'
end


# td-agent
include_recipe 'td-agent'
