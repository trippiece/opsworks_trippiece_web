s3_file node[:sshkey][:path] do
  remote_path node[:sshkey][:source]
  aws_access_key_id node[:aws][:key]
  aws_secret_access_key node[:aws][:secret]
  bucket node[:aws][:s3_bucket]
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
