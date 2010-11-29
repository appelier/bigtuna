atom_feed do |feed|
  feed.title("#{@project.name} CI")
  feed.updated(@builds.first.updated_at)
 
  @builds.each do |build|
    feed.entry(build, :published => build.created_at) do |entry|
      entry.title("#{build.display_name} - #{build.status == Build::STATUS_OK ? "SUCCESS" : "FAILED"}")
      entry.content(build.commit_message)
      entry.updated(build.updated_at)
      entry.author do |author|
        author.name(build.author)
      end
    end
  end
end
