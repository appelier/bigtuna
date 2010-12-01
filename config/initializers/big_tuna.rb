module BigTuna
  VCS_BACKENDS = [
    VCS::Git,
  ]

  HOOKS = [
    Hooks::Mailer,
    Hooks::Xmpp
  ]

  DEFAULT_CONFIG = {
    "read_only" => false,
  }

  def self.config
    return @config if @config
    config = DEFAULT_CONFIG.dup
    if File.file?("config/bigtuna.yml")
      config.merge!(YAML.load_file("config/bigtuna.yml")[Rails.env] || {})
    end
    @config = config
  end

  def self.github_secure
    config["github_secure"]
  end

  def self.read_only?
    env_force = ["true", "1", "yes", "y"].include?(ENV["BIGTUNA_READONLY"].to_s.downcase)
    return true if env_force
    config["read_only"]
  end
end
