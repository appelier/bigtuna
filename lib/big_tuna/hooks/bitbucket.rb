module BigTuna
  class Hooks::Bitbucket < Hooks::Base
    NAME = 'bitbucket'

    attr_accessor :url, :vcs_sources, :vcs_branch

    def parse(payload)
      @url = payload["repository"]["absolute_url"]

      @vcs_sources = Hash.new
      @vcs_sources[:public] = "TODOFIXMETHISHOULDNEVERBEVALID" # TODO: add bitbucket public rul
      @vcs_sources[:private] = "ssh://hg@bitbucket.org#{url}"

      @vcs_branch = payload["commits"][0]["branch"]
    end
  
  end
end
