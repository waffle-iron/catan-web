class LikesController < ApplicationController
  before_filter :authenticate_user!
  load_and_authorize_resource :post
  load_and_authorize_resource :like, through: :post, shallow: true

  def create
    @like.user = current_user
    @like.save

    respond_to do |format|
      format.js
    end
  end

  def cancel
    @like = @post.likes.find_by user: current_user
    @like.destroy

    respond_to do |format|
      format.js
    end
  end
end