app_directory = "#{node[:app][:directory]}/#{node[:app][:host]}"

supervisor_service "celerybeat-#{node[:app][:name]}" do
  command "#{::File.join(node[:virtualenv][:path], 'bin', 'celery')} beat -l info"
  autostart true
  autorestart true
  startsecs 10
  stopwaitsecs 21600
  environment :DJANGO_SETTINGS_MODULE => node[:app][:django_settings],
              :ENV_PYTHON => "#{node[:virtualenv][:path]}/bin/python",
              :CELERY_BIN => "#{node[:virtualenv][:path]}/bin/celery",
              :CELERY_APP => node[:app][:name],
              :CELERYBEAT_USER => node[:app][:owner],
              :CELERYBEAT_GROUP => node[:app][:group],
              :CELERYBEAT_CHDIR => "#{app_directory}/#{node[:app][:name]}",
              :CELERYBEAT_OPTS => "--schedule=/var/run/celery/celerybeat-schedule"
  user node[:app][:owner]
  directory "#{app_directory}/#{node[:app][:name]}"
  stderr_logfile "#{node[:supervisor][:log_dir]}/celerybeat-#{node[:app][:name]}-stderr.log"
end
