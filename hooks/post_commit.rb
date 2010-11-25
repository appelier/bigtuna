require "rubygems"
require "httparty"
require "yaml"

if File.file?("config/big_tuna_hooks.yml")
  config = YAML.load_file("config/big_tuna_hooks.yml")
  HTTParty.post("#{config["big_tuna_url"]}/hooks/#{config["hook_name"]}", :body => {})
end
