# stop sendmail first.
service 'sendmail' do
  action [:disable, :stop]
end
# install
include_recipe 'postfix'
# copy sasl db
s3_file '/etc/postfix/sasl_passwd.db' do
  remote_path node[:postfix][:main][:sasl_passwd_s3]
  aws_access_key_id node[:aws][:key]
  aws_secret_access_key node[:aws][:secret]
  bucket node[:aws][:s3_bucket]
  mode 0600
  not_if { ::File.exists?('/etc/postfix/sasl_passwd.db') }
  notifies :restart, "service[postfix]", :immediately
end