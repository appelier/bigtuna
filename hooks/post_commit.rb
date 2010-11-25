require "rubygems"
require "httparty"
require "yaml"

if File.file?("config/big_tuna_hooks.yml")
  config = YAML.load_file("config/big_tuna_hooks.yml")
  HTTParty.post("#{config["big_tuna_url"]}/hooks/post_commit", :body => {:name => config["project_name"]})
end
