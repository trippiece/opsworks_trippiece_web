cookbook_file node[:sshignorehost][:path] do
  source 'wrap-ssh4git.sh'
  mode 0755
end
