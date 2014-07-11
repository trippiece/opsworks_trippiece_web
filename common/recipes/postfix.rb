# stop sendmail first.
service 'sendmail' do
  action [:disable, :stop]
end
# install
include_recipe 'postfix'
include_recipe 's3'
# copy sasl db
s3_file '/etc/postfix/sasl_passwd.db' do
  source node[:postfix][:main][:sasl_passwd_s3]
  access_key_id node[:aws][:key]
  secret_access_key node[:aws][:secret]
  mode 0600
  not_if { ::File.exists?('/etc/postfix/sasl_passwd.db') }
  notifies :restart, "service[postfix]", :immediately
end