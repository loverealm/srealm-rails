class Api::V1::Pub::RelationshipsController < Api::V1::BaseController
  def follow
    current_user.follow(User.find(params[:followed_id]))
    head(status: :created) && return
  end

  def unfollow
    current_user.unfollow(User.find(params[:followed_id]))
    render(nothing: true)
  end
end
