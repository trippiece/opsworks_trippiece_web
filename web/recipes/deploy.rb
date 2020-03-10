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

# install gems
bash 'bundle install' do
  cwd app_directory
  user node[:app][:owner]
  group node[:app][:group]
  code <<-EOC
  bundle install
  EOC
end

# install compilers of less and coffeescript.
bash 'npm install --production' do
  cwd app_directory
  code <<-EOC
  npm config set user 0
  npm config set unsafe-perm true
  npm install --production
  EOC
end

# grunt deploy
bash "grunt deploy" do
  cwd app_directory
  if [:revision] == 'tp2'
    code <<-EOC
    grunt deploy --target=production
    EOC
  else
    code <<-EOC
    /usr/local/bin/node --max-old-space-size=4096 /usr//local/bin/grunt deploy
    EOC
  end
end

# install react dependencies
bash "npm install" do
  cwd "#{app_directory}/#{node[:app][:name]}/assets/js/"
  code <<-EOC
  npm install
  EOC
end

# build react
bash "npm run build" do
  cwd "#{app_directory}/#{node[:app][:name]}/assets/js/"
  code <<-EOC
  npm run build
  EOC
end

# collectstatic
bash "manage.py" do
  cwd "#{app_directory}/#{node[:app][:name]}"
  user node[:app][:owner]
  group node[:app][:group]
  code <<-EOC
  #{node[:virtualenv][:path]}/bin/python manage.py collectstatic --noinput --settings=#{node[:app][:django_settings]} -i rest_framework -i admin --no-post-process
  EOC
end

# restart supervisor services.
%W{gunicorn-#{node[:app][:name]} celeryd-#{node[:app][:name]}}.each do |srv|
  supervisor_service srv do
    action :restart
  end
end
