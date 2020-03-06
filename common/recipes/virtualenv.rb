# install python and other required packages.
%w{python27 python27-devel}.each do |pkg|
  package pkg do
    action :upgrade
  end
end

include_recipe "python::pip"

python_pip "virtualenv" do
  version "16.7.7"
  action :install
end

directory node[:virtualenv][:parent] do
  owner node[:app][:owner]
  group node[:app][:group]
  mode 0755
  action :create
end

python_virtualenv node[:virtualenv][:path] do
  owner node[:app][:owner]
  group node[:app][:group]
  interpreter "python27"
  action :create
end