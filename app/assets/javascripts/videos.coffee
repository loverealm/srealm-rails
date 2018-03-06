class @VideoPlayer
  constructor: (@video) ->
    @check_duration_flag = false
    @check_duration_viewing()
    @video_autoplay()

  # Play video without sound if it is in the field of vision
  # And and when you click on a video unmute
  video_autoplay: ->
    $(@video).on 'inview', (event, is_in_view) =>
      video = event.currentTarget
      unless is_in_view
        video.pause()
      return
      
      if is_in_view
        video.play()
        video.volume = 0
        $(video).click (e) ->
          if video.volume == 0
            video.volume = 1
            video.play()
      else
        video.pause()
  
  # Check viewing time and up viewing couner if user watched 1/5 video      
  check_duration_viewing:  ->
    $(@video).on 'play', (event) =>
      video = event.currentTarget
      unless @check_duration_flag
        counter = new VideoViewCounter(video)
        @check_duration_flag = true

class VideoViewCounter
  constructor: (@video) ->
    @video.addEventListener 'loadedmetadata', =>
      @video_duration = $(@video).get(0).duration

      # time = 1/5 video time 
      @time_for_up_view = @video_duration / 5 
      @start_time = $(@video).get(0).currentTime
      @view_time = 0
      
      # On events video pause and play
      @pause_video()
      @play_video()

      # the remaining time for up view counter
      @time_lost = @time_for_up_view
      
      # Run timeout and pinpoint the beginning of time
      @timer_id = setTimeout(@check_view_time, (@time_lost+1)*1000) #ms = sec * 1000, +1 - delay
      @start_timer = Date.now()
  # end initialize


  play_video: ->
    $(@video).on 'play', =>
      @start_timer = Date.now()
      @start_time = $(@video).get(0).currentTime
      @time_lost -= @time_passed
      @timer_id = setTimeout(@check_view_time, (@time_lost)*1000)
        
  pause_video: ->
    $(@video).on 'pause', =>
      clearTimeout(@timer_id)
      @time_passed = (Date.now() - @start_timer) / 1000  # sec = ms / 1000
      @view_time += @time_passed
      
      if @video_duration == $(@video).get(0).currentTime
        $(@video).off('play');
        @play_video()
        @time_passed = 0
        @time_lost = @time_for_up_view + 1
        @view_time = 0
  
  # if timeout end to check viewing time
  check_view_time: =>
    end_time = $(@video).get(0).currentTime
    @view_time += end_time - @start_time