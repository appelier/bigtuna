module BigTuna
  VCS_BACKENDS = [
    VCS::Git,
  ]

  HOOKS = [
    Hooks::Mailer,
    Hooks::Xmpp
  ]

  def self.read_only?
    env_force = ["true", "1", "yes", "y"].include?(ENV["BIGTUNA_READONLY"].to_s.downcase)
    return true if env_force
    if File.file?("config/bigtuna.yml")
      config = YAML.load_file("config/bigtuna.yml")[Rails.env]
      config["read_only"]
    else
      false
    end
  end
end
