class Project < ActiveRecord::Base
  STATUS_NOT_BUILT = "status_not_built"
  attr_accessor :hook_update

  has_many :builds, :dependent => :destroy
  has_many :step_lists, :dependent => :destroy
  before_destroy :remove_build_folder
  before_update :rename_build_folder
  before_create :set_default_build_counts
  after_save :update_hooks
  
  validates :hook_name, :uniqueness => {:allow_blank => true}
  validates :name, :presence => true, :uniqueness => true
  validates :vcs_type, :inclusion => BigTuna.vcses.map { |e| e::VALUE }
  validates :vcs_source, :presence => true
  validates :vcs_branch, :presence => true
  
  validate :validate_vcs_incremental_support
  
  acts_as_list

  def self.ajax_reload?
    case BigTuna.ajax_reload
    when "always" then true
    when "building" then self.all.map(&:recent_build).compact.map(&:ajax_reload?).include?(true)
    else false
    end
  end

  def duplicate_project
    project_clone = self.clone
    project_clone.name += " COPY"

    if !self.hook_name.blank?
      project_clone.update_attributes({:hook_name => self.hook_name + "_copy"})
    end

    if !project_clone.save!
      return nil
    end

    self.step_lists.each do |step_list|
      new_step_list = step_list.clone
      new_step_list.project = project_clone
      new_step_list.save
    end

    project_clone
  end

  def ajax_reload?
    case BigTuna.ajax_reload
    when "always" then true
    when "building" then self.recent_build.try(:ajax_reload?)
    else false
    end
  end

  def recent_build
    builds.order("created_at DESC").first
  end

  def build!
    new_total_builds = self.total_builds + 1
    ActiveRecord::Base.transaction do
      build = self.builds.create!({:scheduled_at => Time.now, :build_no => new_total_builds})
      self.update_attributes!(:total_builds => new_total_builds)
      remove_project_jobs_in_queue()
      Delayed::Job.enqueue(build)
    end
  end

  def hooks
    hook_hash = {}
    BigTuna.hooks.each do |hook|
      hook_hash[hook::NAME] = hook
    end
    Hook.where(:project_id => self.id)
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
    klass = BigTuna.vcses.find { |e| e::VALUE == vcs_type }
    raise ArgumentError.new("VCS not supported: %p" % [vcs_type]) if klass.nil?
    @vcs = klass.new(self.vcs_source, self.vcs_branch)
  end

  def to_param
    [self.id, self.name.to_url].join("-")
  end

  def stability
    last_builds = builds.order("created_at DESC").
      where(:status => [Build::STATUS_OK, Build::STATUS_FAILED, Build::STATUS_BUILDER_ERROR]).
      limit(5)
    statuses = last_builds.map { |e| e.status }
    return -1 if statuses.size < 5
    statuses.count { |e| e == Build::STATUS_OK }
  end

  def hooks=(hooks)
    @_hooks = hooks
  end
  
  def fetch_type
    if self[:fetch_type]
      self[:fetch_type].to_sym
    else
      :clone
    end
  end
  
  private
  def build_dir_from_name(name)
    if BigTuna.build_dir[0] == '/'[0]
      File.join(BigTuna.build_dir, name.downcase.gsub(/[^A-Za-z0-9]/, "_"))
    else
      File.join(Rails.root, BigTuna.build_dir, name.downcase.gsub(/[^A-Za-z0-9]/, "_"))
    end
  end

  def remove_build_folder
    if File.directory?(self.build_dir)
      FileUtils.rm_rf(self.build_dir)
    else
      Rails.logger.debug("[BigTuna] Couldn't find build dir: %p" % [self.build_dir])
    end
  end

  def rename_build_folder
    if self.name_changed? && self.total_builds != 0
      old_dir = build_dir_from_name(self.name_was)
      new_dir = build_dir_from_name(self.name)
      FileUtils.mv(old_dir, new_dir)
    end
  end

  def set_default_build_counts
    self.total_builds = 0
    self.failed_builds = 0
  end

  def update_hooks
    return unless self.hook_update
    new_hooks = (@_hooks || {}).keys
    current_hooks = self.hooks.map { |e| e.hook_name }
    to_remove = current_hooks - new_hooks
    to_add = new_hooks - current_hooks
    Hook.where(:project_id => self.id, :hook_name => to_remove).delete_all
    to_add.each do |name|
      Hook.create!(:project => self, :hook_name => name)
    end
  end

  def remove_project_jobs_in_queue
    jobs_to_destroy = []
    Delayed::Job.all.each do |job|
      build = job.payload_object
      next unless build.is_a?(Build)
      if build.status = Build::STATUS_IN_QUEUE && build.project == self
        jobs_to_destroy << job
      end
    end
    jobs_to_destroy.each { |job| job.destroy }
  end
  
  def validate_vcs_incremental_support
    errors.add(:fetch_type, " #{fetch_type} not support by the vcs") if fetch_type == :incremental && !vcs.support_incremental_build?
  end
end
