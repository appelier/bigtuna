require "machinist/active_record"

Sham.define do
  name { Faker::Name.name }
end

Project.blueprint do
  name { Sham.name }
  max_builds { 3 }
end
