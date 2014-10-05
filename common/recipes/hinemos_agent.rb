filename = "hinemos_agent-4.1.2_rhel5-rhel6.tar.gz"
extracted_filename = "Hinemos_Agent-4.1.2_rhel5-rhel6"

# install required packages.
%w{net-snmp krb5-workstation expect}.each do |pkg|
  package pkg do
    action :upgrade
  end
end

# extra the file.
cookbook_file "/tmp/#{filename}" do
  source "#{filename}"
end

# install the agent.
bash 'installing hinemos_agent' do
  code <<-EOC
    tar xzf /tmp/#{filename} -C /tmp/
    cd /tmp/#{extracted_filename}/
    ./agent_installer_JP.sh -i -m 54.64.74.87 -s
    rm -R /tmp/#{extracted_filename}/
  EOC
end

# start the agent.
service 'hinemos_agent' do
  action [:enable, :start]
end
