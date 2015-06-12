default['app']['api_host'] = ''
default['app']['default_server_name'] = ''
default['app']['revision'] = 'master'
default['app']['grunt_target'] = 'deploy'
default['db']['default']['conn_max_age'] = 60
override['nginx']['cookbook'] = 'retrip'
default['nginx']['custom_block_ips'] = []
default['celery']['config'] = '/etc/default/celeryd'
