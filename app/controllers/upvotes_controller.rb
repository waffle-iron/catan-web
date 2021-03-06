class UpvotesController < ApplicationController
  before_filter :authenticate_user!
  load_and_authorize_resource :comment
  load_and_authorize_resource :upvote, through: :comment, shallow: true

  def create
    @upvote.user = current_user
    @upvote.save

    respond_to do |format|
      format.js
    end
  end

  def cancel
    @upvote = @comment.upvotes.find_by user: current_user
    @upvote.try(:destroy)

    respond_to do |format|
      format.js
    end
  end
end
