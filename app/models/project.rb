class Project < ActiveRecord::Base
  STATUS_NOT_BUILT = "status_not_built"

  has_many :builds, :dependent => :destroy
  before_destroy :remove_build_folder
  before_update :rename_build_folder

  validates :hook_name, :uniqueness => {:allow_blank => true}
  validates :name, :presence => true, :uniqueness => true
  validates :vcs_type, :inclusion => BigTuna::VCS_BACKENDS.map { |e| e[0] }
  validates :vcs_source, :presence => true

  acts_as_list

  def recent_build
    builds.order("created_at DESC").first
  end

  def build!
    head_info, head_command = vcs.head_info
    build = self.builds.create!(head_info.merge(:scheduled_at => Time.now))
    Delayed::Job.enqueue(build)
  end

  def build_dir
    build_dir_from_name(name)
  end

  def truncate_builds!
    builds.order("created_at DESC").offset(self.max_builds).each do |build|
      build.destroy
    end
  end

  def max_builds
    super || 10
  end

  def status
    build = recent_build
    build.nil? ? STATUS_NOT_BUILT : build.status
  end

  def vcs
    return @vcs if @vcs
    klass = BigTuna::VCS_BACKENDS.assoc(vcs_type)[1]
    raise ArgumentError.new("VCS not supported: %p" % [vcs_type]) if klass.nil?
    @vcs = klass.new(self.vcs_source)
  end

  def to_param
    [self.id, self.name.to_url].join("-")
  end

  private
  def build_dir_from_name(name)
    File.join(Rails.root, "builds", name.downcase.gsub(/[^A-Za-z0-9]/, "_"))
  end

  def remove_build_folder
    if File.directory?(self.build_dir)
      FileUtils.rm_rf(self.build_dir)
    else
      Rails.logger.debug("[BigTuna] Couldn't find build dir: %p" % [self.build_dir])
    end
  end

  def rename_build_folder
    if self.name_changed?
      old_dir = build_dir_from_name(self.name_was)
      new_dir = build_dir_from_name(self.name)
      FileUtils.mv(old_dir, new_dir)
    end
  end
end
