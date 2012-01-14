module BigTuna
  class Hooks::GitHub < Hooks::Base
    NAME = 'github'

    attr_accessor :url, :vcs_sources, :vcs_branch

    def parse(payload)
      @url = payload["repository"]["url"]

      @vcs_sources = Hash.new
      @vcs_sources[:public]  = @url.gsub(/^https:\/\//, "git://") + ".git"
      @vcs_sources[:private] = @url.gsub(/^https:\/\//, "git@").
                                 gsub(/github.com\//, "github.com:") + ".git"

      @vcs_branch = payload["ref"].split("/").last
    end

  end
end
