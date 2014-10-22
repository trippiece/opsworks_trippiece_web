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
  #{node[:virtualenv][:path]}/bin/pip install -r requirements.txt
  EOC
end

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

# install compilers of less and coffeescript.
bash 'npm install --production' do
  cwd app_directory
  code <<-EOC
  npm install --production
  EOC
end

# grunt deploy
bash "grunt deploy" do
  cwd app_directory
  code <<-EOC
  grunt deploy
  EOC
end

# downloadcertificate, collectstatic, clearcache, migrate
bash "manage.py" do
  cwd "#{app_directory}/#{node[:app][:name]}"
  user node[:app][:owner]
  group node[:app][:group]
  code <<-EOC
  #{node[:virtualenv][:path]}/bin/python manage.py downloadcertificate --settings=#{node[:app][:django_settings]}
  #{node[:virtualenv][:path]}/bin/python manage.py collectstatic --noinput --settings=#{node[:app][:django_settings]}
  #{node[:virtualenv][:path]}/bin/python manage.py clearcache --settings=#{node[:app][:django_settings]}
  #{node[:virtualenv][:path]}/bin/python manage.py migrate --settings=#{node[:app][:django_settings]}
  EOC
end

# restart gunicorn.
supervisor_service "gunicorn-#{node[:app][:name]}" do
  action :restart
end
