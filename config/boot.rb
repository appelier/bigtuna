require 'rubygems'

ORIGINAL_ENV = {}
ENV.each do |key, value|
  ORIGINAL_ENV[key] = value
end
# Set up gems listed in the Gemfile.
gemfile = File.expand_path('../../Gemfile', __FILE__)
begin
  ENV['BUNDLE_GEMFILE'] = gemfile
  require 'bundler'
  Bundler.setup
rescue Bundler::GemNotFound => e
  STDERR.puts e.message
  STDERR.puts "Try running `bundle install`."
  exit!
end if File.exist?(gemfile)

# puts "ORIGINAL_ENV"
# ORIGINAL_ENV.each do |k, v|
  # puts "%s => %s" % [k, v]
# end
# puts "ENV"
# ENV.each do |k, v|
  # puts "%s => %s" % [k, v]
# end

# ORIGINAL_ENV["PATH"] = ENV["PATH"]
# ORIGINAL_ENV["RUBYOPT"] = ENV["RUBYOPT"]
