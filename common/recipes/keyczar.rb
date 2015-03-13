keyczar_path = "#{node[:app][:directory]}/#{node[:app][:host]}/#{node[:keyczar][:location]}"

# create directory.
directory keyczar_path do
  owner node[:app][:owner]
  group node[:app][:group]
  mode 0700
  recursive true
  action :create
end

# create meta file.
template "#{keyczar_path}/meta" do
  source 'keyczar_meta.erb'
  owner node[:app][:owner]
  group node[:app][:group]
  mode 0600
  action :create
end

# create key file.
template "#{keyczar_path}/1" do
  source 'keyczar_1.erb'
  owner node[:app][:owner]
  group node[:app][:group]
  mode 0600
  action :create
end