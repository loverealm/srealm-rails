module UserHelper
  def show_avatar(user, type_avatar, options = {})
    image_tag(user.avatar_url(options[:time], type_avatar.to_sym), options.except(:time)) if user
  end
  
  # render user's avatar widget
  # size: user's photo dimensions
  # time: period used to show user's name and avatar image based on anonymous status in this period
  # attrs: include_status => false/true means to include the online status
  def user_avatar_widget(user, size = 90, time = nil, attrs = {}, &block)
    attrs = {class: '', include_status: false, img_class: ''}.merge(attrs)
    attrs[:class] << ' user_avatar_widget_styled ' if attrs[:include_status]
    attrs[:img_class] << ' current-user-avatar ' if user.id == current_user.id
    link_to(user_profile_url(user, time), class: "avatar_widget #{attrs[:class]}", title: user.full_name(false, time), 'data-id' => user.id) do
      media_avatar_image(user.avatar_url(time), size, {alt: user.full_name(false, time), class: attrs[:img_class]}) + (block ? capture(&block) : '') + (attrs[:include_status] ? user.decorate.the_online_status : '')
    end
  end
  
  # return a image tag for media thumbnail
  # settings = {include_link: false, custom_class: ''}
  def media_avatar_image(thumb_url, size = 90, settings = {})
    settings = {include_link: false, class: '', alt: ''}.merge(settings)
    res = image_tag(thumb_url, alt: settings[:alt], class: 'media-object img-responsive avatar_image ' << settings[:class], style: "#{"width: #{size}px; height: #{size}px; min-width: #{size}px;" if size}")
    res = link_to(res, thumb_url, target: '_blank') if settings[:include_link]
    res
  end
  
  # return the cache key for users (takes control of name not updated at)
  def user_cache_key(user)
    "#{user.id}_#{user.updated_at.to_i}"
  end
  
  # render follow button
  def follow_button(other_user, attrs = {})
    attrs = {btn_class: 'btn btn-default', class: ''}.merge(attrs)
    attrs[:extra_class] = attrs[:class]
    attrs[:class] = attrs[:btn_class]
    if current_user.following?(other_user)
      other_user.decorate.the_unfollow_link(attrs)
    else
      other_user.decorate.the_follow_link(attrs)
    end
  end

  # return the corresponding link button for church
  def counselor_list_button(counselor, custom_class = '')
    link_to('Video Counseling', '#', class: 'start_video_counseling btn btn-primary btn-sm '+custom_class, 'data-user-id' => counselor.id)
  end
  
  # returns user's profile url based on anonymous status 
  # time: (Time) time period to check the anonymous status
  # _params = {}, extra params for the url link
  def user_profile_url(user, time = nil, _params = {})
    if(time && user.was_anonymity?(time)) || user.try(:is_deactivated?)
      'javascript:void(0)'
    else
      dashboard_profile_path(user, _params)
    end
  end
  
  # generate user link html tag according current user status: banned, anonymity, deactivated
  #   ownerize: true/false (default false) permit to add extra 's to mark as owner of something
  #   params: extra url params for url link
  def link_to_user(user, attrs = {}, &block)
    attrs = {mark: true, time: nil, label: nil, ownerize: false, class: '', params: {}}.merge(attrs)
    attrs[:label] = user ? user.full_name(attrs[:mark], attrs[:time]) : 'Guest' if attrs[:label].nil?
    attrs[:label] = "#{attrs[:label]}'s" if attrs[:ownerize]
    link_to (block ? capture(&block) : attrs[:label]), user_profile_url(user, attrs[:time], attrs[:params]), attrs.except(:mark, :time, :params, :ownerize, :label)
  end
  
  # return user row widget
  #   user: User Model
  #   settings: {thumb_size: 60, class: '', truncate: 50, time: nil, media_left: '', media_right: '', include_status: false/true, link: true (user name as link or static text)}
  def user_row_widget(user, settings = {}, &block)
    settings = {link: true, thumb_size: 60, class: '', truncate: 50, media_left: '', media_right: '', time: nil, include_status: false}.merge(settings)
    name = user.full_name(false, settings[:time])
    "<div data-id='#{user.id}' class='media #{settings[:class]}'>
      <div class='media-left post_relative'>
        #{user_avatar_widget(user, settings[:thumb_size], settings[:time], include_status: settings[:include_status])}
        #{settings[:media_left]}
      </div>
      <div class='media-body'>
        <div class='media-heading'>
          #{settings[:link] ? link_to(name, user_profile_url(user, settings[:time])) : name}
        </div>
        <p class='small'>
          #{user.the_biography(settings[:truncate], settings[:time])}
        </p>
        #{block ? capture(&block) : ''}
      </div>
      #{ "<div class='media-right'>#{settings[:media_right]}</div>" if settings[:media_right].present? }
    </div>".html_safe
  end
  
end
