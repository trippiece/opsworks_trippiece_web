include_recipe 'td-agent'
# create position file directory.
directory '/var/lib/fluentd' do
  owner 'td-agent'
  group 'td-agent'
  action :create
end
# add td-agent hack
cookbook_file 'rsyslog.conf' do
  path '/etc/rsyslog.conf'
  action :create
end
# loosen permissions
%w{/var/log/messages /var/log/secure}.each do |file_path|
  file file_path do
    mode 0644
    action :create
  end
end
# restart rsyslog
service 'rsyslog' do
  action :restart
end