atom_feed do |feed|
  feed.title("#{@project.name} CI")
  feed.updated(@builds.first.updated_at)

  status_displays = {
    Build::STATUS_OK => "SUCCESS",
    Build::STATUS_FAILED => "FAILED",
    Build::STATUS_PROGRESS => "IN PROGRESS"
  }

  @builds.each do |build|
    feed.entry(build, :published => build.created_at) do |entry|
      display_status = status_displays[build.status] || "UNKNOWN"

      entry.title("#{build.display_name} - #{display_status}")
      entry.content(build.commit_message)
      entry.updated(build.updated_at)
      entry.author do |author|
        author.name(build.author)
      end
    end
  end
end
