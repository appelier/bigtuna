class StepList < ActiveRecord::Base
  belongs_to :project
  has_many :shared_variables

  validates :steps, :presence => true
  validate :steps_cant_be_comments_only

  def steps_cant_be_comments_only
    comments_only = true
    steps.split('\n').each do |line|
      comments_only = false if line[0..0] != '#'
    end
    errors.add(:steps, "can't be comments only") if comments_only
  end
end
