include_recipe 's3'

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

# git clone
directory node[:app][:directory] do
  owner node[:app][:owner]
  group node[:app][:group]
  mode 0755
  action :create
end

app_directory = "#{node[:app][:directory]}/#{node[:app][:host]}"

git app_directory do
  repository node[:app][:repository]
  revision node[:app][:revision]
  action :sync
  user node[:app][:owner]
  group node[:app][:group]
  ssh_wrapper node[:sshignorehost][:path]
end
