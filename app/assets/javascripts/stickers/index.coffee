window.stickerPipeConfig =

  apiKey: '082dfba4998f71a4ef630f62b8a60ca8',

  enableEmojiTab: true,
  enableHistoryTab: true,
  enableStoreTab: true,

  htmlForEmptyRecent: 'You have not submitted any sticker',
  storagePrefix: 'prefix_',
  lang: 'en',

  userId: 'yaw@loverealm.org',
  userPremium: false,
  userData: {
    age: 20,
    gender: 'male'
  },

  priceB: '0.99 $',
  priceC: '1.99 $'


class StickersSingleton
  constructor: ->
    @stickers = new Stickers stickerPipeConfig
    @cache = {}

  # make an elelment into stick
  # callback function receives: (sticker/emoji text, is emoji (true) or sticker(false) boolean, link_opener object, stickerpipe object)
  makeStickeable: (element, callback) ->
    config = {}
    config[k] = v for k,v of window.stickerPipeConfig
    config.elId = element.attr('id')
    stickerpipe = new Stickers(config)
    
    stickerpipe.render ->
      stickerpipe.onClickSticker (text) ->
        callback(text, false, element, stickerpipe) if callback
      stickerpipe.onClickEmoji((emoji)->
        callback(emoji, true, element, stickerpipe) if callback
      )

  # check if a string is a sticker or emoji
  is_emoji_sticker: (str)->
    str ||= ''
    ranges = ['\ud83c[\udf00-\udfff]', '\ud83d[\udc00-\ude4f]', '\ud83d[\ude80-\udeff]']
    !!str.match(ranges.join('|')) || @stickers.isSticker(str)

        

window.stickersSingleton = new StickersSingleton()
