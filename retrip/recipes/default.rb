include_recipe 'common::virtualenv'

# install required packages.
%w{libmemcached libmemcached-devel npm libjpeg-devel}.each do |pkg|
  package pkg do
    action :upgrade
  end
end

# install grunt-cli
bash 'npm install -g grunt-cli' do
  code <<-EOC
  npm install -g grunt-cli
  EOC
end

include_recipe 'common::postgresql'

include_recipe 'common::postfix'

include_recipe 'common::repository'

include_recipe 'common::keyczar'

# supervisor must be called before gunicorn and celeryd.
include_recipe 'supervisor'

include_recipe 'common::gunicorn'

include_recipe 'common::celeryd'

include_recipe 'common::celerybeat'

include_recipe 'common::dynamic_dynamodb'

include_recipe 'common::nginx'

# install api site-config
unless node[:app][:api_host].empty?
  nginx_web_app node[:app][:api_host] do
    cookbook node[:nginx][:cookbook]
    template 'nginx_site_api.erb'
  end
end

include_recipe 'common::td-agent'
# configuration
template "/etc/td-agent/td-agent.conf" do
  source 'td-agent.conf.erb'
  action :create
  # no need to notify since the template is subscribed.
end
