#source 'https://api.berkshelf.com' # for version 3
site :opscode  # for version 2

# build-essential 2.3.0 contains bug.
cookbook 'build-essential', '= 2.2.4'
cookbook 'python'
# 2014-07-31
cookbook 'supervisor', github: 'poise/supervisor', ref: 'e5ad4bf21c2aa4dc56e7bad84b836d897a87dedf'
cookbook 'gunicorn'
cookbook 'td-agent', github: 'treasure-data/chef-td-agent', ref: '7a0fb20d56e620d04dac3c6d547734a398d2dff6'
cookbook 'postfix'
