class Issue < ActiveRecord::Base
  include Watchable
  include UniqueSoftDeletable
  acts_as_unique_paranoid

  TITLE_OF_PARTI_PARTI = '빠띠'
  SLUG_OF_PARTI_PARTI = 'parti'

  # relations
  has_many :relateds
  has_many :related_issues, through: :relateds, source: :target
  has_many :posts, dependent: :destroy
  has_many :comments, through: :posts
  has_many :articles, through: :posts, source: :postable, source_type: Article
  has_many :opinions, through: :posts, source: :postable, source_type: Opinion
  has_many :talks, through: :posts, source: :postable, source_type: Talk
  has_many :notes, through: :posts, source: :postable, source_type: Note
  # 이슈는 위키를 하나 가지고 있어요.
  has_one :wiki
  has_many :makers do
    def merge_nickname
      self.map { |m| m.user.nickname }.join(',')
    end
  end

  # validations
  validates :title, presence: true, uniqueness: { case_sensitive: false }
  VALID_SLUG = /\A[a-z0-9_-]+\z/i
  validates :slug,
    presence: true,
    format: { with: VALID_SLUG },
    exclusion: { in: %w(campaign app new edit index session login logout users admin
    stylesheets assets javascripts images) },
    uniqueness: { case_sensitive: false },
    length: { maximum: 100 }

  # fields
  mount_uploader :logo, ImageUploader
  mount_uploader :cover, ImageUploader
  attr_accessor :makers_nickname

  # callbacks
  before_save :downcase_slug
  before_create :build_wiki

  # scopes
  scope :hottest, -> { order('issues.watches_count + issues.posts_count desc') }

  # search
  scoped_search on: [:title, :body]

  # methods
  def made_by? someone
    makers.exists? user: someone
  end

  def is_all?
    false
  end

  def slug_formated_title
    return if self.title.blank?
    self.slug = self.title.strip.downcase.gsub(/\s+/, "-")
  end

  def related_with? something
    relateds.exists?(target: something)
  end

  def past_week?
    created_at > 1.week.ago
  end

  def recommends
    recommends = (Issue.past_week + Issue.hottest.limit(10)).uniq.shuffle.first(10)
    (related_issues + recommends - [self]).uniq.shuffle.first(10)
  end

  def featured_posts(count)
    result = []
    posts.only_articles.hottest.limit(50).each do |post|
      result << post if (post.specific.has_image? and !post.specific.hidden?)
      return result if result.length > count
    end
    result
  end

  def self.basic_issues
    Issue.where basic: true
  end

  def counts_container
    counts = OpenStruct.new
    counts.articles_count = articles.count
    counts.latest_articles_count = articles.latest.count
    counts.comments_count = comments.count
    counts.latest_comments_count = comments.latest.count
    counts.opinions_count = opinions.count
    counts.latest_opinions_count = opinions.latest.count
    counts.talks_count = talks.count
    counts.latest_talks_count = talks.latest.count
    counts
  end

  def hottest_posts(count)
    posts.hottest.limit(count)
  end

  private

  def downcase_slug
    return if slug.blank?
    self.slug = slug.downcase
  end
end
