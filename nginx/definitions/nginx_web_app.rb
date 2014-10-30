define :nginx_web_app, :template => "nginx_site.erb", :enable => true do
  include_recipe "nginx::service"

  application = params[:application]
  application_name = params[:name]

  template "#{node[:nginx][:dir]}/sites-available/#{application_name}" do
    Chef::Log.debug("Generating Nginx site template for #{application_name}")
    source params[:template]
    owner "root"
    group "root"
    mode 0644
    if params[:cookbook]
      cookbook params[:cookbook]
    end
    variables(
      :application => application,
      :application_name => application_name,
      :params => params
    )
    if File.exists?("#{node[:nginx][:dir]}/sites-enabled/#{application_name}")
      notifies :reload, "service[nginx]", :delayed
    end
  end

  file "#{node[:nginx][:dir]}/sites-enabled/default" do
    action :delete
    only_if do
      File.exists?("#{node[:nginx][:dir]}/sites-enabled/default")
    end
  end

  if params[:enable]
    execute "nxensite #{application_name}" do
      command "/usr/sbin/nxensite #{application_name}"
      notifies :reload, "service[nginx]"
      not_if do File.symlink?("#{node[:nginx][:dir]}/sites-enabled/#{application_name}") end
    end
  else
    execute "nxdissite #{application_name}" do
      command "/usr/sbin/nxdissite #{application_name}"
      notifies :reload, "service[nginx]"
      only_if do File.symlink?("#{node[:nginx][:dir]}/sites-enabled/#{application_name}") end
    end
  end
end
