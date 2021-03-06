class UsersController < ApplicationController
  before_filter :authenticate_user!, only: :kill_me

  def index
    @users = User.order("id DESC")
  end

  def comments
    fetch_user
    @comments = @user.comments.recent.limit(25).previous_of params[:last_id]
    @is_last_page = (@comments.empty? or @user.comments.recent.previous_of(@comments.last.try(:id)).empty?)
  end

  def upvotes
    fetch_user
    @upvotes = @user.upvotes.recent.limit(25).previous_of params[:last_id]
    @is_last_page = (@upvotes.empty? or @user.upvotes.recent.previous_of(@upvotes.last.try(:id)).empty?)
    @comments = @upvotes.map(&:comment)
  end

  def votes
    fetch_user

    previous_last_vote = Vote.find_by(id: params[:last_id])

    @votes = @user.votes.recent.previous_of_vote(previous_last_vote).limit(20)
    current_last_vote = @votes.last

    @is_last_page = (@user.votes.empty? or @user.votes.recent.previous_of_vote(current_last_vote).empty?)

    @posts = @votes.map(&:post).compact
    @opinions = @posts.map(&:specific).compact
  end

  def summary_test
    User.limit(100).each do |user|
      PartiMailer.summary_by_mailtrap(user).deliver_later
    end
    render text: 'ok'
  end

  def kill_me
    current_user.update_attributes(uid: SecureRandom.hex(10))
    sign_out current_user
    redirect_to root_path
  end

  private

  def fetch_user
    @user ||= User.find_by! nickname: params[:nickname].try(:downcase)
  end
end
