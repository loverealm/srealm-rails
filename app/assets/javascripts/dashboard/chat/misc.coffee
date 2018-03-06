class @OnlineChecker
  constructor: (@callback) ->
    @usersOnlineCache = []

  start: =>
    if @timer
      console.log 'Already running status checker'
      return
    interval = 60 * 1000
    @timer = setInterval(@getOnlineUsers, interval)

  stop: =>
    clearInterval @timer
    @timer = null

  getOnlineUsers: =>
    $.getJSON '/dashboard/search/get_online_users', (res) =>
      @usersOnlineCache = res
      @callback?(res)
  
  isUserOnline: (userId) ->
    parseInt(userId) in @usersOnlineCache

class @AvatarHelper
  @getAvatarUrl: (proposedURL) ->
    proposedURL

  @getAvatarStatus: (status, format) ->
    if format == 'class'
      return if status then 'online' else ''
    if format == 'full_title'
      return if status then 'User Online' else 'User Offline'
    if status then 'Online' else 'Offline'


class @TimeHelper
  @format: (dateOrTimestamp) ->
    return 'Never' unless dateOrTimestamp?
    date = if dateOrTimestamp instanceof Date
        dateOrTimestamp
      else
        new Date( dateOrTimestamp * 1000 )

    if new Date() - date < 24 * 60 * 60 * 1000
      hours = date.getHours()
      minutes = date.getMinutes()
      ampm = if hours >= 12 then 'pm' else 'am'
      hours = hours % 12
      hours = 12 if hours is 0
      hours = '0' + hours if hours < 10
      minutes = '0' + minutes if minutes < 10
      return hours + ':' + minutes + ' ' + ampm
    else
      day = date.getDate()
      day = '0' + day if day < 10
      month = date.getMonth() + 1
      month = '0' + month if month < 10
      year = date.getYear()
      year += 1900 if year < 1900 # normalize
      year = year % 100

      return "#{day}/#{month}/#{year}"
