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

s3_file node[:sshkey][:path] do
  source node[:sshkey][:source]
  access_key_id node[:aws][:key]
  secret_access_key node[:aws][:secret]
  owner node[:app][:owner]
  group node[:app][:group]
  mode 0600
end

git "#{node[:app][:directory]}/#{node[:app][:host]}" do
  repository node[:app][:repository]
  revision "master"
  action :sync
  user node[:app][:owner]
  group node[:app][:group]
  ssh_wrapper "ssh -i #{node[:sshkey][:path]}"
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
supervisor_service "gunicorn-#{node[:app][:name]}" do
  command "#{::File.join(node[:virtualenv][:path], 'bin', 'gunicorn')} #{node[:app][:wsgi]} -c #{gunicorn_config_path}"
  autostart true
  autorestart true
  user node[:app][:owner]
  directory "#{node[:app][:directory]}/#{node[:app][:host]}/#{node[:app][:name]}"
end


# nginx
include_recipe 'nginx'
nginx_web_app node[:app][:host] do
  cookbook 'nginx'
end


# td-agent
include_recipe 'chef-td-agent'
