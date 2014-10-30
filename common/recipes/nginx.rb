include_recipe 'nginx'
nginx_web_app node[:app][:host] do
  cookbook node[:nginx][:cookbook]
end