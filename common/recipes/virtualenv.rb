# install python and other required packages.
%w{python35 python35-devel}.each do |pkg|
  package pkg do
    action :upgrade
  end
end

bash 'pip install virtualenv' do
  code <<-EOC
  pip install --user virtualenv
  EOC
end

include_recipe 'python::virtualenv'

directory node[:virtualenv][:parent] do
  owner node[:app][:owner]
  group node[:app][:group]
  mode 0755
  action :create
end

python_virtualenv node[:virtualenv][:path] do
  owner node[:app][:owner]
  group node[:app][:group]
  interpreter "python35"
  action :create
end