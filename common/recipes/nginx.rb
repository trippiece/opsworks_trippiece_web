include_recipe 'nginx'

# yum install httpd-tools
package 'httpd-tools' do
  action :upgrade
end

# make .htpasswd
node[:nginx][:basic_auth_entries].each_with_index do |entry, index|
  htpasswd_cmd = 'htpasswd -b'
  if index == 0
    htpasswd_cmd += 'c'
  end
  bash 'htpasswd' do
    code <<-EOC
      #{htpasswd_cmd} #{node[:nginx][:basic_auth_file]} '#{entry[:username]}' '#{entry[:password]}'
    EOC
  end
end

# install site-config
nginx_web_app node[:app][:host] do
  cookbook node[:nginx][:cookbook]
end