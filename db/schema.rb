# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20110326142448) do

  create_table "build_parts", :force => true do |t|
    t.integer  "build_id",         :null => false
    t.string   "name"
    t.text     "steps"
    t.text     "output"
    t.string   "status"
    t.datetime "started_at"
    t.datetime "finished_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "shared_variables"
  end

  create_table "builds", :force => true do |t|
    t.integer  "project_id"
    t.string   "commit"
    t.string   "status"
    t.text     "output"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "build_dir"
    t.datetime "started_at"
    t.datetime "scheduled_at"
    t.string   "author"
    t.string   "email"
    t.datetime "committed_at"
    t.text     "commit_message"
    t.datetime "finished_at"
    t.integer  "build_no"
  end

  create_table "delayed_jobs", :force => true do |t|
    t.integer  "priority",   :default => 0
    t.integer  "attempts",   :default => 0
    t.text     "handler"
    t.text     "last_error"
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string   "locked_by"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "delayed_jobs", ["priority", "run_at"], :name => "delayed_jobs_priority"

  create_table "hooks", :force => true do |t|
    t.integer  "project_id",    :null => false
    t.string   "hook_name",     :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "configuration"
    t.text     "hooks_enabled"
  end

  create_table "projects", :force => true do |t|
    t.string   "name",                               :null => false
    t.string   "vcs_type",                           :null => false
    t.string   "vcs_source",                         :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "max_builds"
    t.string   "hook_name"
    t.integer  "position"
    t.string   "vcs_branch"
    t.integer  "total_builds"
    t.integer  "failed_builds"
    t.string   "fetch_type",    :default => "clone"
  end

  create_table "shared_variables", :force => true do |t|
    t.integer  "step_list_id"
    t.string   "name"
    t.string   "value"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "step_lists", :force => true do |t|
    t.string   "name"
    t.text     "steps"
    t.integer  "project_id", :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

end
