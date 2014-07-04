name             "opsworks_deploy_python"
maintainer       "Alec Mitchell"
maintainer_email "alecpm@gmail.com"
license          "BSD License"
description      "Deploys and configures zc.buildout based applications"
long_description  IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          "0.0.1"

supports "ubuntu"

depends "deploy"
depends "python"
depends "gunicorn"

recipe "opsworks_deploy_python", "Install and setup a python application in a virtualenv"
recipe "opsworks_deploy_python::django", "Install and setup a django based python application"
