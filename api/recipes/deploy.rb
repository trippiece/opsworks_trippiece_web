include_recipe 'ssh_ignore_host'

app_directory = "#{node[:app][:directory]}/#{node[:app][:host]}"

# deploy
deploy app_directory do
  repository node[:app][:repository]
  revision "master"
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


# restart supervisor services.
%w{gunicorn-#{node[:app][:name]} celeryd-#{node[:app][:name]}}.each do |srv|
  supervisor_service srv do
    action :restart
  end
end
