class Vote < ActiveRecord::Base
  extend Enumerize
  include PostTouchable
  include Choosable

  belongs_to :user
  belongs_to :post, counter_cache: true

  validate :validate_post_type
  validates :user, uniqueness: {scope: [:post]}
  validates :post, presence: true
  validates :choice, presence: true

  scope :recent, -> { order(updated_at: :desc) }
  scope :agreed, -> { where(choice: 'agree') }
  scope :disagreed, -> { where(choice: 'disagree') }

  before_save :touch_post_by_vote

  private

  def validate_post_type
    unless [Opinion.to_s, Answer.to_s].include?(post.postable_type)
      errors.add(:post, "should be opinion or answer")
    end
  end
end
