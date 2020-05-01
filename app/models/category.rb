class Category < ApplicationRecord
  include CommunityRelated

  has_and_belongs_to_many :post_types
  has_many :posts
  belongs_to :tag_set

  serialize :display_post_types, Array

  validates :name, uniqueness: { scope: [:community_id] }

  def has_new_posts_for(user)
    key = "#{community_id}/#{user.id}/#{id}/last_visit"
    ap "Category: #{id} (#{name})"
    ap "Rails cache: #{Rails.cache.read(key)}"
    ap "Redis: #{RequestContext.redis.get(key)}"
    ap "Last activity: #{(posts.maximum(:last_activity) || Date.parse).iso8601}"
    Rails.cache.fetch key, expires_in: 5.minutes do
      Rack::MiniProfiler.step "Redis: category last visit (#{key})" do
        last_visit = RequestContext.redis.get(key)
        last_visit.nil? || (posts.maximum(:last_activity) || DateTime.parse) > DateTime.parse(last_visit)
      end
    end
  end
end