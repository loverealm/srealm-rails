module UserGroupHelper
  def user_group_image_widget(group, size = 90, &block)
    link_to(dashboard_user_group_path(group), class: 'user_group_img_widget') do
      media_avatar_image(group.image.url, size) + (block ? capture(&block) : '')
    end
  end

  # return user row widget
  #   user: User Model
  #   settings: {thumb_size: 60, custom_class: '', truncate: 50}
  def user_group_row_widget(user_group, settings = {}, &block)
    settings = {thumb_size: 60, class: '', truncate: 50}.merge(settings)
    "<div class='media #{settings[:class]}'>
      <div class='media-left'>
        #{user_group_image_widget(user_group, settings[:thumb_size])}
      </div>
      <div class='media-body'>
        <div class='media-heading'>
          #{link_to(user_group.name, dashboard_user_group_path(user_group))}
        </div>
        <p class='small'>
          #{user_group.excerpt(settings[:truncate])}
        </p>
        #{block ? capture(&block) : ''}
      </div>
    </div>".html_safe
  end
  
  # append google search churches to the results list
  # @param results: User Group collection of results
  # @param query: text query to search
  # @param radius: circle radius in meters for google nearby search
  # @return array of results including google places
  def user_group_add_map_results(results, query = '', radius = '')
    results = results.to_a
    params[:lat] = app_get_geo_data_by_ip.try(:latitude) unless params[:lat]
    params[:lng] = app_get_geo_data_by_ip.try(:longitude) unless params[:lng]
    uri = "https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=#{(params[:lat] && params[:lng]) ? [params[:lat], params[:lng]].join(',') : '-33.86407799999999,151.205095'}&radius=#{radius.presence || 30000}&type=church&keyword=#{query}...&key=#{ENV['GOOGLE_PLACES_API_KEY']}"
    uri += "&pagetoken=#{params[:next_page_token]}" if params[:next_page_token]
    response = JSON.parse(HTTParty.get(uri).body)
    params[:next_page_token] = response['next_page_token']

    obj = Struct.new(:name, :description, :photo, :latitude, :longitude, :place_id){ def id; end; def the_description(qty); description.to_s.truncate(qty); end; }
    params[:church_google_items] = response['results'].count
    response['results'].each do |res|
      lat, lng = [res['geometry']['location']['lat'], res['geometry']['location']['lng']]
      results << obj.new(res['name'], res['vicinity'], res['icon'], lat, lng, res['place_id']) unless UserGroup.churches.search_by_geolocation(lat, lng).any?
    end
    # results.sort_by{|obj| obj.name }
    results
  end
  
  # return the full information of a google place (church)
  def google_map_place_info(place_id)
    JSON.parse(HTTParty.get("https://maps.googleapis.com/maps/api/place/details/json?placeid=#{place_id}&key=#{ENV['GOOGLE_PLACES_API_KEY']}").body)['result']
  end
  
  # render report periods dropdown
  def report_periods_dropdown(&block)
    dropdown_builder right: true, button_class: 'btn-sm', list_class: 'report_periods' do
      content_tag(:li, link_to('This Month', '#', 'data-period' => 'this_month'), class: 'active') +
      content_tag(:li, link_to('Last Month', '#', 'data-period' => 'last_month')) +
      content_tag(:li, link_to('Last 6 Months', '#', 'data-period' => 'last_6_months')) +
      content_tag(:li, link_to('This Year', '#', 'data-period' => 'this_year')) +
      (block ? capture(&block) : '')
    end
  end
end