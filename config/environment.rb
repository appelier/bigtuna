# Load the rails application
require File.expand_path('../application', __FILE__)

# load bigtuna module before init so init can use the settings
require File.expand_path('../../lib/big_tuna', __FILE__)

# Initialize the rails application
BigTuna::Application.initialize!
