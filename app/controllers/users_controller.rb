class UsersController < ApplicationController
  def index
    @users = User.order("id DESC")
  end

  def comments
    fetch_user
    @comments = @user.comments.recent.limit(25).previous_of params[:last_id]
    @is_last_page = (@comments.empty? or @user.comments.recent.previous_of(@comments.last.id).empty?)
  end

  def upvotes
    fetch_user
    @upvotes = @user.upvotes.recent.limit(25).previous_of params[:last_id]
    @is_last_page = (@upvotes.empty? or @user.upvotes.recent.previous_of(@upvotes.last.id).empty?)
    @comments = @upvotes.map(&:comment)
  end

  def votes
    fetch_user
    @votes = @user.votes.recent.page params[:page]
    @posts = @votes.map(&:post).compact
    @opinions = @posts.map(&:specific).compact
  end

  def summary_test
    User.limit(100).each do |user|
      PartiMailer.summary_by_mailtrap(user).deliver_later
    end
    render text: 'ok'
  end

  private

  def fetch_user
    @user ||= User.find_by! nickname: params[:nickname].try(:downcase)
  end
end
