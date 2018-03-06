class Dashboard::ContentsController < Dashboard::BaseController
  skip_before_action :attack_app_before_load, only: :widget_popular_content
  before_action :set_content, except: [:index, :live_board, :create, :upload_image, :new_live_video, :widget_popular_content]
  respond_to :html, :json, :js

  # show contents filtered for a hash tag
  def index
    params[:tag_id] = HashTag.find_by_name(params[:tag_key]).try(:id) if params[:tag_key].present?
    @current_trending = HashTag.find(params[:tag_id]) if params[:tag_id].present? && !params[:page].present?
    newsfeed_service = NewsfeedService.new(current_user, params[:page], params[:per_page] || 6)
    @contents = newsfeed_service.recent_content(params[:tag_id])
    render partial: 'dashboard/contents/list', locals: { contents: @contents } if request.format == 'text/javascript'
  end
  
  # return all new contents for specific hash tag
  # GET /dashboard/contents/live_board?hash_tag=loverealm
  def live_board
    return redirect_to root_path, error: 'Hash tag not found' unless (@hash_tag = HashTag.find_by_name(params[:hash_tag])).present?
    newsfeed_service = NewsfeedService.new(current_user, params[:page], params[:per_page] || 6)
    @contents = newsfeed_service.recent_content(@hash_tag.id)
    render layout: false
  end
  
  # similar to news feed but this order content by popularity rather than most recent content
  def widget_popular_content
  end

  # show full content information
  def show
    @hash_tags_recommended_contents = Content.recommendations_by_hash_tags(current_user, @content)
    @popular_contents = Content.recommendations_by_popularity(current_user, @content)
    @recommended_stories = @hash_tags_recommended_contents.order('RANDOM()').limit(2).concat @popular_contents.order('RANDOM()').limit(3)
    @recommended_stories = @recommended_stories.uniq
  end
  
  # load a single content widget
  def widget
    render partial: 'dashboard/contents/list', locals: { contents: Content.where(id:@content.id) }
  end

  def create
    @content = Content.new(content_params)
    if params[:content][:owner_id].present?
      owner_id = ApplicationHelper.decrypt_text(params[:content][:owner_id])
      if owner_id == current_user.id
        @content.user_id = current_user.id
      else
        @content.user_id = owner_id
        @content.owner_id = current_user.id
      end
    else
      @content.user_id = current_user.id
    end
    
    authorize! :post, @content.user_group if @content.user_group_id
    if @content.save
      callback_after_save(@content)
      render partial: "dashboard/contents/#{@content.content_type}", locals: { content: @content }
    else
      render_error_model(@content)
    end
  end

  def edit
    authorize! :modify, @content
    view = case @content.content_type
             when 'status', 'story'
               'status_form'
             when 'image', 'video'
               'image_form'
             else
               "#{@content.content_type}_form"
           end
    render partial: view, layout: false, locals:{content: @content }
  end

  def update
    authorize! :modify, @content
    @content.update_attributes(content_params)
    callback_after_save(@content)
    render partial: "dashboard/contents/#{@content.content_type}", locals: { content: @content }
  end

  def destroy
    authorize! :modify, @content
    if @content.destroy
      render nothing: true
    else
      render_error_model(@content)
    end
  end

  # update content file's visits counter
  def mark_file_visited
    file = @content.content_images.find(params[:file_id])
    visit = file.content_file_visitors.new(user: current_user)
    if visit.save
      render json: {visits: file.visits_counter}
    else
      render_error_model visit
    end
  rescue
    render_error_messages ['Content file not found']
  end
  
  # increments visitors quantity for current live video content
  def visit_live_video
    @content.content_live_video.visit!(current_user)
    head(:ok)
  end
  
  def toogle_like
    authorize! :show, @content
    if params[:like] == 'true'
      @content.like_for current_user, params[:kind]
    else
      @content.unlike_for current_user
    end
    render nothing: true
  end

  # upload temporal images for image story
  # params: files (array of images), tmp_key (String temporal identificator to use on save)
  # return json
  def upload_image
    res = []
    params[:images].each do |image|
      image = ContentFile.new(image: image, tmp_key: params[:tmp_images_key])
      if image.save
        res << {id: image.id, url: image.image.url(:thumb)}
      else
        res << {errors: image.errors.full_messages.join(', ')}
      end
    end
    render json: res
  end
  
  def add_prayers
    authorize! :invite_prayers, @content
    if request.get?
      render layout: false
    else
      @content.add_prayers(current_user.id, params[:users_prayer_ids], [], params[:emails])
      render_success_message('Prayer invitation sent')
    end
  end
  
  def prayer_reject
    authorize! :show, @content
    @content.content_prayers.where(user_id: current_user.id).first.try(:reject!)
    render_success_message('Prayer request rejected', '<small class="text-gray">Request rejected</small>')
  end

  def prayer_accept
    authorize! :show, @content
    @content.content_prayers.where(user_id: current_user.id).first.try(:accept!)
    render_success_message('Prayer request accepted', render_to_string(partial: 'dashboard/users/my_praying_list_of_others', locals: {content_prayers: current_user.content_prayers.where(content_id: @content.id)}))
  end
  
  # render list of people who likes current content
  def likes
    authorize! :show, @content
    if params[:kind].present?
      @users = @content.voters_for(params[:kind]).reorder('voted_at ASC').page(params[:page]).per(20)
    else
      @users = @content.voters.reorder('voted_at ASC').page(params[:page]).per(20)
    end
    render 'likes', layout: false
  end
  
  # mark current pray as answered  
  def answer_pray
    authorize! :modify, @content
    if params[:share]
      @content.answer_pray_share!
      render_success_message('Your testimony has been successfully shared!!')
    else
      @content.answer_pray!
      @items = current_user.content_prayers.where(content_id: @content.id).page(1).per(5)
      render layout: false
    end
  end

  # stop praying _user_id for current praying feed  
  def stop_praying
    if @content.stop_praying!(current_user.id)
      render_success_message("Your prayer has been successfully stopped.")
    else
      render_error_model(@content)
    end
  end
  
  def new_live_video
    user_group = UserGroup.find(params[:user_group_id])
    authorize! :modify, user_group, message: 'Feature available only for UserGroup Administrators'
    session = OpentokService.service.create_session :media_mode => :routed
    token = session.generate_token({role: :moderator, expire_time: Time.now.to_i+(7 * 24 * 60 * 60), data: '', initial_layout_class_list: ['focus', 'inactive'] })
    render partial: 'live_video_form', locals: {content: current_user.contents.new(content_type: 'live_video', user_group_id: user_group.id), session: session, token: token}
  end
  
  # stop live video streaming
  def stop_live_video
    @content.content_live_video.try(:stop_streaming!)
    render partial: "dashboard/contents/#{@content.content_type}", locals: { content: @content }
  end
  
  private
  def set_content
    @content = Content.find(params[:content_id] || params[:id])
    authorize! :show, @content
  end

  def content_params
    # recommended users to pray this request + extra recommended users to pray
    if params[:content].keys.include?('users_prayer_ids') && params[:suggested_users].present?
      params[:content][:users_prayer_ids] = params[:content][:users_prayer_ids] + params[:suggested_users].split(',')
    end
    
    # recommended users to answer this question + extra recommended users to answer questions
    if params[:content].keys.include?('user_recommended_ids') && params[:suggested_users].present?
      params[:content][:user_recommended_ids] = params[:content][:user_recommended_ids] + params[:suggested_users].split(',') 
    end

    params[:content][:content_live_video_attributes].try(:encode_base64_files!, :screenshot)
    params.require(:content).permit(:description, :video, :title, :image, :content_type, :tags, :bootsy_image_gallery_id, :user_group_id, user_recommended_ids: [], content_image_ids: [], users_prayer_ids: [], content_live_video_attributes: [:session])
  end

  # function executed after created/updated content
  def callback_after_save(content)
    if params[:content][:content_image_ids].present? && content.is_picture?
      params[:content][:content_image_ids].each_with_index{|image_id, index| content.content_images.find(image_id).update_column(:order_file, index) }
      content.content_images.reload
    end
  end
end