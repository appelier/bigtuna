module BigTuna
  DEFAULT_CONFIG = {
    "read_only" => false
  }

  def self.config
    return @config if @config
    config = DEFAULT_CONFIG.dup
    if File.file?("config/bigtuna.yml")
      config.merge!(YAML.load_file("config/bigtuna.yml")[Rails.env] || {})
    end
    @config = config
  end

  def self.ajax_reload
    config["ajax_reload"]
  end

  def self.github_secure
    config["github_secure"]
  end

  def self.read_only?
    env_force = ["true", "1", "yes", "y"].include?(ENV["BIGTUNA_READONLY"].to_s.downcase)
    return true if env_force
    config["read_only"]
  end

  def self.logger
    @_logger = Logger.new("log/bigtuna_#{Rails.env}.log")
  end

  def self.hooks
    @_hooks ||= []
  end

  def self.vcses
    @_vcses ||= []
  end
end

Dir[File.join(Rails.root, "extras", "big_tuna", "vcs", "*.rb")].each { |vcs| require_dependency(vcs) }
Dir[File.join(Rails.root, "extras", "big_tuna", "hooks", "*.rb")].each { |hook| require_dependency(hook) }
