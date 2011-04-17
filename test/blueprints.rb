require "machinist/active_record"

Sham.define do
  name { Faker::Name.name }
  email { Faker::Internet.user_name + "@example.org" }
  commit(:unique => false) { "a" * 40 }
end

Project.blueprint do
  name { Sham.name }
  max_builds { 1 }
  vcs_type { "git" }
  vcs_source { "test/files/repo" }
  vcs_branch { "master" }
  hook_update { true }
end

StepList.blueprint do
  name { Sham.name }
  steps { "ls -al\ntrue" }
  project { Project.make }
end

Build.blueprint do
  project { Project.make }
  scheduled_at { Time.now }
  commit { Sham.commit }
end
