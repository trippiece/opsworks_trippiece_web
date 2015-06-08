app_directory = "#{node[:app][:directory]}/#{node[:app][:host]}"

# deploy git repository.
git app_directory do
  repository node[:app][:repository]
  revision node[:app][:revision]
  user node[:app][:owner]
  group node[:app][:group]
  ssh_wrapper node[:sshignorehost][:path]
  action :sync
end

# pip install
bash "pip install -r requirements.txt" do
  cwd app_directory
  user node[:app][:owner]
  group node[:app][:group]
  code <<-EOC
  export HOME=~#{node[:app][:owner]}
  #{node[:virtualenv][:path]}/bin/pip install -r requirements.txt
  EOC
end

# install compilers of less and coffeescript.
bash 'npm install --production' do
  cwd app_directory
  code <<-EOC
  npm install --production
  EOC
end

# grunt deploy
bash "grunt #{node[:app][:grunt_target]}" do
  cwd app_directory
  code <<-EOC
  grunt #{node[:app][:grunt_target]}
  EOC
end

# downloadcertificate, collectstatic, clearcache, migrate
bash "manage.py" do
  cwd "#{app_directory}/#{node[:app][:name]}"
  user node[:app][:owner]
  group node[:app][:group]
  code "#{node[:virtualenv][:path]}/bin/python manage.py downloadcertificate --settings=#{node[:app][:django_settings]} && " +
       "#{node[:virtualenv][:path]}/bin/python manage.py collectstatic --noinput --settings=#{node[:app][:django_settings]} && " +
       "#{node[:virtualenv][:path]}/bin/python manage.py migrate --settings=#{node[:app][:django_settings]} && " +
       "#{node[:virtualenv][:path]}/bin/python manage.py clearcache --settings=#{node[:app][:django_settings]}"
end

# start or reload gunicorn depending on the current status.
if `supervisorctl status gunicorn-#{node[:app][:name]} | awk '{print $2}'` == 'RUNNING'
  # reload it.
  bash "reload gunicorn" do
    code <<-EOC
    supervisorctl status gunicorn-#{node[:app][:name]} | sed "s/.*[pid ]\([0-9]\+\)\,.*/\1/" | xargs kill -HUP
    EOC
  end
else
  # or start it.
  supervisor_service "gunicorn-#{node[:app][:name]}" do
    action :restart
  end
end


# restart celery services.
%W{celeryd-#{node[:app][:name]} celerybeat-#{node[:app][:name]}}.each do |srv|
  supervisor_service srv do
    action :restart
  end
end

# clearcache again after the restart to make sure that the old cache is all cleared.
bash "manage.py clearcache" do
  cwd "#{app_directory}/#{node[:app][:name]}"
  user node[:app][:owner]
  group node[:app][:group]
  code <<-EOC
  #{node[:virtualenv][:path]}/bin/python manage.py clearcache --settings=#{node[:app][:django_settings]}
  EOC
end