class StepList < ActiveRecord::Base
  belongs_to :project
  has_many :shared_variables
end
