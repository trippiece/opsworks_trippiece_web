package 'git' do
  action :install
end

%w{python27 python27-devel python-pip}.each do |pkg|
  package pkg do
    action :upgrade
  end
end

include_recipe 'python::virtualenv'

directory node[:virtualenv][:location] do
  mode 0755
  action :create
end

python_virtualenv "#{node[:virtualenv][:location]}/api" do
  interpreter "python27"
  action :create
end


%w{mysql mysql-devel}.each do |pkg|
  package pkg do
    action :upgrade
  end
end


include_recipe 'gunicorn'

include_recipe 'nginx'
nginx_web_app node[:hostname] do
  cookbook 'nginx'
end

include_recipe 'chef-td-agent'
