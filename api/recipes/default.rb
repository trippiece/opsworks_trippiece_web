# install python and other required packages.
%w{python27 python27-devel python-pip mysql mysql-devel libjpeg-devel}.each do |pkg|
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


include_recipe 's3'


# postfix
# stop sendmail first.
service 'sendmail' do
  action [:disable, :stop]
do
# install
include_recipe 'postfix'
# copy sasl db
s3_file '/etc/postfix/sasl_passwd.db' do
  source node[:postfix][:main][:sasl_passwd_s3]
  access_key_id node[:aws][:key]
  secret_access_key node[:aws][:secret]
  mode 0600
  not_if { ::File.exists?('/etc/postfix/sasl_passwd.db') }
  notifies :restart, "service[postfix]", :immediately
end


# git clone
directory node[:app][:directory] do
  owner node[:app][:owner]
  group node[:app][:group]
  mode 0755
  action :create
end

s3_file node[:sshkey][:path] do
  source node[:sshkey][:source]
  access_key_id node[:aws][:key]
  secret_access_key node[:aws][:secret]
  owner node[:app][:owner]
  group node[:app][:group]
  mode 0600
  not_if { ::File.exists?(node[:sshkey][:path]) }
end

include_recipe 'ssh_ignore_host'

app_directory = "#{node[:app][:directory]}/#{node[:app][:host]}"
git app_directory do
  repository node[:app][:repository]
  revision "master"
  action :sync
  user node[:app][:owner]
  group node[:app][:group]
  ssh_wrapper node[:sshignorehost][:path]
end


# pip install
bash "pip install -r requirements.txt" do
  cwd app_directory
  code <<-EOC
  #{node[:virtualenv][:path]}/bin/pip install -r requirements.txt
  EOC
  not_if { ::File.exists?("#{node[:virtualenv][:path]}/bin/celery") }
end


# place credential files.
template "#{app_directory}/#{node[:app][:name]}/#{node[:app][:name]}/settings_base_credential.py" do
  source 'settings_base_credential.py.erb'
  action :create
end

template "#{app_directory}/#{node[:app][:name]}/#{node[:app][:name]}/#{node[:app][:credential]}" do
  source 'settings_env_credential.py.erb'
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
  stderr_logfile "#{node[:supervisor][:log_dir]}/gunicorn-#{node[:app][:name]}-stderr.log"
end
# for celeryd
supervisor_service "celeryd-#{node[:app][:name]}" do
  command "#{::File.join(node[:virtualenv][:path], 'bin', 'celery')} worker -l info"
  autostart true
  autorestart true
  startsecs 10
  stopwaitsecs 600
  environment :DJANGO_SETTINGS_MODULE => node[:app][:django_settings],
              :CELERYD_NODES => node[:app][:name],
              :CELERYD_CHDIR => "#{app_directory}/#{node[:app][:name]}",
              :ENV_PYTHON => "#{node[:virtualenv][:path]}/bin/python",
              :CELERY_BIN => "#{node[:virtualenv][:path]}/bin/celery",
              :CELERY_APP => node[:app][:name],
              :CELERYD_OPTS => "--time-limit=300 --concurrency=8",
              :CELERYD_USER => node[:app][:owner],
              :CELERYD_GROUP => node[:app][:group]
  user node[:app][:owner]
  directory "#{app_directory}/#{node[:app][:name]}"
  stderr_logfile "#{node[:supervisor][:log_dir]}/celeryd-#{node[:app][:name]}-stderr.log"
end


# nginx
include_recipe 'nginx'
nginx_web_app node[:app][:host] do
  cookbook 'nginx'
end


# td-agent
include_recipe 'td-agent'
# create position file directory.
directory '/var/lib/fluentd' do
  owner 'td-agent'
  group 'td-agent'
  action :create
end
# add td-agent hack
cookbook_file 'rsyslog.conf' do
  path '/etc/rsyslog.conf'
  action :create
end
# loosen permissions
%w{/var/log/messages /var/log/secure}.each do |file_path|
  file file_path do
    mode 0644
    action :create
  end
end
# restart rsyslog
service 'rsyslog' do
  action :restart
end
# configuration
template "/etc/td-agent/td-agent.conf" do
  source 'td-agent.conf.erb'
  action :create
  # no need to notify since the template is subscribed.
end
