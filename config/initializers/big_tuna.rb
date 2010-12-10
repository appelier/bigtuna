Dir[File.join("extras", "big_tuna", "vcs", "*.rb")].each { |vcs| require_dependency(vcs) }
Dir[File.join("extras", "big_tuna", "hooks", "*.rb")].each { |hook| require_dependency(hook) }
