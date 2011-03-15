Dir[File.join(Rails.root, "lib", "big_tuna", "vcs", "*.rb")].each { |vcs| require_dependency(vcs) }
Dir[File.join(Rails.root, "lib", "big_tuna", "hooks", "*.rb")].each { |hook| require_dependency(hook) }

BigTuna.create_build_dir
