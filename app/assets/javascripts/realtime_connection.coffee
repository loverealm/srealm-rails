class @RealTimeConnection
  constructor: ->
    @private_listeners = []
    @common_listeners = []
    @channel_subscriptions = {}
    return unless window['CURRENT_USER']
    # { channel="demo_tutorial", message: '....',  subscribedChannel="demo_tutorial",  timetoken="14836992421232094",  subscription: '', publisher: '', }
    pubnubDemo.addListener({ message: (channel_message) =>
      message = JSON.parse(channel_message.message)
      channel_message['message'] = message
      #console.log("Instant notification received: ", channel_message)
      if moment().subtract(20, 'seconds').unix() < message.sent_at
        console.log("Calling notification callback: ", message)
        for callback in (@channel_subscriptions[channel_message['channel']] || [])
          callback(message.data)
    })


  # subscribe to listen current session's notifications
  subscribeToPrivateChannel: (callback) =>
    @prv_channel ||= $('meta[name=cryptedHash]').attr("content")
    @subscribeToChannel(@prv_channel, callback)

  # subscribe to listen public notifications
  subscribeToPublicChannel: (callback) =>
    @common_channel ||= $('meta[name=commonHash]').attr('content')
    @subscribeToChannel(@common_channel, callback)

  # subscribe to listen to specific key
  subscribeToChannel: (key, callback) =>
    return unless window['CURRENT_USER']
    key = key
    pubnubDemo.subscribe({ channels: [key] }) unless @channel_subscriptions[key]
    @channel_subscriptions[key] ||= []
    @channel_subscriptions[key].push(callback)

window['real_time_connector'] = new RealTimeConnection()