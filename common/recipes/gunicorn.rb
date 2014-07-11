include_recipe 'gunicorn'

gunicorn_config_path = "/etc/gunicorn/#{node[:app][:name]}.py"
gunicorn_config gunicorn_config_path do
  listen '127.0.0.1:8000'
  worker_processes (node['cpu'] && node['cpu']['total']) && [node['cpu']['total'].to_i * 2 + 1, 8].min || 5
  worker_max_requests 8192
  action :create
end

# supervisor config for gunicorn
supervisor_service "gunicorn-#{node[:app][:name]}" do
  command "#{::File.join(node[:virtualenv][:path], 'bin', 'gunicorn')} #{node[:app][:wsgi]} -c #{gunicorn_config_path}"
  autostart true
  autorestart true
  user node[:app][:owner]
  directory "#{app_directory}/#{node[:app][:name]}"
  stderr_logfile "#{node[:supervisor][:log_dir]}/gunicorn-#{node[:app][:name]}-stderr.log"
end