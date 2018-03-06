require 'fcm'
require 'pubnub'
# Class which permits to publish realtime actions to browser and mobile devices
module PubSub
  class Publisher
    # @param [Array or Collection] users: users who will receive this notification
    # @param [String] key: name or key for the notification
    # @param [Hash] data_message: notification data message to send
    # @param [Hash] settings: {
    #     only_mobile: false*/true,
    #     only_web: false*/true,
    #     title: 'String' text title message for ios
    #     body: 'String' text body message for ios
    #   }
    def publish_for(users, key, data_message, settings = {})
      # case key
      #   when 'new_feedd'
      #     users = users.followers
      # end
      @settings = settings || {}
      @subscribers = users.is_a?(Integer) ? [users] : users
      @payload = {type: key}.merge(data_message)
      delivery!
    end

    # Send notification to specific channel
    # @param channel_name [String]: key or name of the channel 
    # @param [String] key: name or key for the notification
    # @param [Hash] data_message: notification data message to send
    # @param [Hash] settings: Same as publish method
    def publish_to(channel_name, key, data_message, settings = {})
      @settings = settings || {}
      @publish_to_channel = channel_name
      @payload = {type: key}.merge(data_message)
      delivery!
    end

    # Same as publish_to but sending to public channel
    def publish_to_public(key, data_message, settings = {})
      publish_to(ENV['FCM_PUBLIC_TOPIC'], key, data_message, settings)
    end
    
    def self.connector
      @_connector ||= Pubnub.new(
          subscribe_key: ENV['PUB_NUB_SUBSKEY'],
          publish_key: ENV['PUB_NUB_PUBLISHKEY'],
          logger: Logger.new('/dev/null')
      )
    end
    
    def self.mobile_connector
      @_mobile_connector ||= FCM.new(ENV['FCM_API_KEY'])
    end

    private
    # delivery instant notification
    def delivery!
      Thread.abort_on_exception=false
      Thread.new do
        unless @settings[:only_mobile]
          channels =  @publish_to_channel ? [@publish_to_channel] : define_channel(@subscribers)
          Rails.logger.info("========Sending web notification key: #{@payload[:type]} to channel: #{channels.join(',')}")
          data = @payload.merge(@settings[:body] || @settings[:title] ? {notification: {title: @settings[:title], body: @settings[:body]}} : {})
          channels.each{|channel| self.class.connector.publish(channel: channel, message: {channel: channel, data: data, sent_at: Time.current.to_i}.to_json) }
        end
        publish_mobile unless @settings[:only_web]
        Rails.logger.info("=======Publisher end")
        ActiveRecord::Base.connection.close
      end
    end

    # publish events to mobile devices
    def publish_mobile
      fcm = self.class.mobile_connector
      options = {data: @payload, priority: 'high', 'notId' => Time.current.to_i, notification: {}}
      options['collapse_key'] = @settings[:group] if @settings[:group].present?
      options_ios = options.dup
      if @settings[:silence] # TODO: test if it is arriving to device
        options_ios[:aps] = {"content-available" => 1}
      else
        options_ios[:notification] = options_ios[:notification].merge({body: @settings[:body] || "key: #{@payload[:type]}" || 'na', title: @settings[:title] || 'na', sound: 'default'})
      end
      if @publish_to_channel # send notification to specific channel
        ios_channel = "ios_#{@publish_to_channel}"
        Rails.logger.info("========Sending mobile android notification to channel: #{@publish_to_channel}")
        Rails.logger.info("========Sending mobile ios notification to channel: #{ios_channel}")
        response_android = fcm.send_to_topic(@publish_to_channel, options)
        response_ios = fcm.send_to_topic(ios_channel, options_ios)
        Rails.logger.info("======== Notifications result android: #{response_android}")
        Rails.logger.info("======== Notifications result ios: #{response_ios}")
      
      else
        android_tokens = []
        ios_tokens = []
        @subscribers.each do |subscriber|
          subscriber.mobile_tokens.each do |item|
            next if item.kind == 'ios' && item.current_mode == 'background' && @settings[:foreground]
            item.kind == 'ios' ? ios_tokens.push(item.fcm_token) : android_tokens.push(item.fcm_token)
          end
        end
        
        unless @settings[:only_ios]
          Rails.logger.info("======== Sending mobile android notifications to: #{android_tokens.join(',')}")
          response_android = android_tokens.each_slice(1000).to_a.map{|tokens| fcm.send(tokens, options) }.first if android_tokens.any?
          Rails.logger.info("======== Notifications result android: #{response_android}") if response_android
        end
        unless @settings[:only_android]
          Rails.logger.info("======== Sending mobile ios notifications to: #{ios_tokens.join(',')}")
          response_ios = ios_tokens.each_slice(1000).to_a.map{|tokens| fcm.send(tokens, options_ios) }.first if ios_tokens.any?
          Rails.logger.info("======== Notifications result ios: #{response_ios}") if response_ios
        end
      end
    end
    
    # include all channels listener for current event
    def define_channel(subscribers, channels = [])
      subscribers.each do |subscriber|
        channels << subscriber.crypted_hash if subscriber.online?
      end
      channels
    end
  end
end