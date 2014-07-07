default['virtualenv']['parent'] = '/var/virtualenv'
default['virtualenv']['path'] = "#{default['virtualenv']['parent']}/#{default['app']['host']}"
default["gunicorn"]["virtualenv"] = default['virtualenv']['path']
default['app']['owner'] = "ec2-user"
default['app']['group'] = "ec2-user"