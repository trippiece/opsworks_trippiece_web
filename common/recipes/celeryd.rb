app_directory = "#{node[:app][:directory]}/#{node[:app][:host]}"

supervisor_service "celeryd-#{node[:app][:name]}" do
  command "#{::File.join(node[:virtualenv][:path], 'bin', 'celery')} worker -l info --concurrency=4"
  autostart true
  autorestart true
  startsecs 10
  stopwaitsecs 21600
  environment :DJANGO_SETTINGS_MODULE => node[:app][:django_settings],
              :CELERYD_NODES => node[:app][:name],
              :CELERYD_CHDIR => "#{app_directory}/#{node[:app][:name]}",
              :ENV_PYTHON => "#{node[:virtualenv][:path]}/bin/python",
              :CELERY_BIN => "#{node[:virtualenv][:path]}/bin/celery",
              :CELERY_APP => node[:app][:name],
              :CELERYD_USER => node[:app][:owner],
              :CELERYD_GROUP => node[:app][:group]
  user node[:app][:owner]
  directory "#{app_directory}/#{node[:app][:name]}"
  stderr_logfile "#{node[:supervisor][:log_dir]}/celeryd-#{node[:app][:name]}-stderr.log"
end
