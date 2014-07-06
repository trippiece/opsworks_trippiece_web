package 'git' do
  action :install
end

%w{python27 python27-devel python-pip}.each do |pkg|
  package pkg do
    action :upgrade
  end
end

include_recipe 'python::virtualenv'

virtualenv_dir = '/var/virtualenv'

directory virtualenv_dir do
  mode 0755
  action :create
end

python_virtualenv "#{virtualenv_dir}/api" do
  interpreter "python27"
  action :create
end


%w{mysql mysql-devel}.each do |pkg|
  package pkg do
    action :upgrade
  end
end