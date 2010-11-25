class HooksController < ApplicationController
  skip_before_filter :verify_authenticity_token

  def post_commit
    Project.where(:name => params[:name]).first.build!
    render :text => "ok", :status => 200
  end
end
