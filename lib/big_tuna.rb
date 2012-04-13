module BigTuna
  VERSION = "0.1.5"

  DEFAULT_CONFIG = {
    "read_only" => false,
    "build_dir" => "builds"
  }

  extend self

  def config
    return @config if @config
    config = DEFAULT_CONFIG.dup
    if File.file?("config/bigtuna.yml")
      config.merge!(YAML.load_file("config/bigtuna.yml")[Rails.env] || {})
    end
    config["read_only"] = true if to_bool(ENV["BIGTUNA_READONLY"])
    @config = config.symbolize_keys!
  end

  [:ajax_reload, :github_secure, :log, :bitbucket_secure, :build_dir, :read_only].each do |key|
    define_method key do
      config[key]
    end
  end

  alias_method :read_only?, :read_only

  def logger
    @_logger ||= self.log ? Logger.new(self.log) : Rails.logger
  end

  def hooks
    @_hooks ||= []
  end

  def vcses
    @_vcses ||= []
  end

  def create_build_dir
    Dir.mkdir(File.join(Rails.root, self.build_dir), 0754) unless File.directory?(File.join(Rails.root, self.build_dir))
  end

  private
  def to_bool(value)
    return value if [true, false, nil].include?(value)
    if value.respond_to?(:to_s)
      return true if ['true', '1', 'yes', 'y'].include?(value.to_s.downcase)
      return false if ['false', '0', 'no', 'n', ''].include?(value.to_s.downcase)
    end
    raise ArgumentError, "unrecognized value #{value.inspect} for boolean"
  end
end
