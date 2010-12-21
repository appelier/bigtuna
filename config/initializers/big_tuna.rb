Dir[File.join(Rails.root, "extras", "big_tuna", "vcs", "*.rb")].each { |vcs| require_dependency(vcs) }
Dir[File.join(Rails.root, "extras", "big_tuna", "hooks", "*.rb")].each { |hook| require_dependency(hook) }
