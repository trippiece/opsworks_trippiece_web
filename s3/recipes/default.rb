require File.expand_path("../../libraries/s3_file.rb", __FILE__)

%w{nokogiri aws-sdk}.each do |name|
  chef_gem name do
    action :install
  end
end
