class Recommend < ActiveRecord::Base
	include PublicActivity::Model
	tracked only: [:create], owner: lambda{|controller, model| model.content.user }, recipient: :user, trackable_type: 'Recommend'
	belongs_to :content
	belongs_to :user
	has_many :activities, ->{ where(trackable_type: 'Recommend') }, class_name: 'PublicActivity::Activity', foreign_key: :trackable_id, dependent: :destroy

	validates :user_id, presence: true
	after_create :notify_content_owner

	def notify_content_owner
    	PubSub::Publisher.new.publish_for([user], 'recommended_to_answer', {source: content.as_basic_json, user: content.user.as_basic_json}, {title: content.user.full_name(false, created_at), body: "recommended you to answer this question: #{content.the_title}"})
	end
end
