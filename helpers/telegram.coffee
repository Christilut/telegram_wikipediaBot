bot = null
botname = null

module.exports =

  setBot: (b, name) ->
    bot = b
    botname = name

  textGroup: (incoming, msg) ->
    # TODO no selective, shows keyboard to all

  textPersonalKeyboardCustom: (incoming, msg, keyboard, markup) ->

    console.log 'sending: ' + msg.substring(0, Math.min(20, msg.length)) + '...'

    reply_markup =
      keyboard: keyboard
      selective: true
      resize_keyboard: true
      one_time_keyboard: true

    if markup
      for key in Object.keys markup
        reply_markup[key] = markup[key]

    bot.sendMessage
      chat_id: incoming.chat.id
      text: randomlyAddRateAd incoming, msg
      reply_markup: reply_markup
      reply_to_message_id: incoming.message_id
      (e) ->
        if e?
          if e.code == 'ECONNRESET'
            console.log 'bot send error: ' + JSON.stringify e
          else if e.error_code == 403 then console.log 'bot send error: ' + JSON.stringify e
          else if e.error_code == 400 then console.log 'bot send error: ' + JSON.stringify e
          else throw 'unhandled bot send error: ' + JSON.stringify e

  textPersonalKeyboardList: (incoming, msg, buttons, markup, show_preview) ->

    buttonArray = []
    for b in buttons
      buttonArray.push [b]

    if not markup then markup = {}
    markup.disable_web_page_preview = true
    if show_preview == true then markup.disable_web_page_preview = false

    module.exports.textPersonalKeyboardCustom incoming, msg, buttonArray, markup

  textPersonal: (incoming, msg, show_preview, markup) ->
    console.log 'sending: ' + msg.substring(0, Math.min(20, msg.length)) + '...'

    reply_markup =
      selective: true
      hide_keyboard: true

    if markup
      for key in Object.keys markup
        reply_markup[key] = markup[key]

    reply_markup.disable_web_page_preview = true
    if show_preview == true then reply_markup.disable_web_page_preview = false

    bot.sendMessage
      chat_id: incoming.chat.id
      text: randomlyAddRateAd incoming, msg
      reply_markup: reply_markup
      reply_to_message_id: incoming.message_id
      (e) ->
        if e?
          if e.code == 'ECONNRESET'
            console.log 'bot send error: ' + JSON.stringify e
          else if e.error_code == 403 then console.log 'bot send error: ' + JSON.stringify e
          else if e.error_code == 400 then console.log 'bot send error: ' + JSON.stringify e
          else throw 'unhandled bot send error: ' + JSON.stringify e

  textPersonalWithPreview: (incoming, msg, markup) ->
    textPersonal incoming, msg, true, markup


  sendDocument: (incoming, files, markup, callback) ->
    console.log 'sending document'
    bot.sendDocument
      chat_id: incoming.chat.id
      reply_markup: markup
      reply_to_message_id: incoming.message_id
      # file_id: files.document_id
      files: {
        document: files.document
      }
      (json) ->
        if json and json.ok == false
          if json.code == 'ECONNRESET'
            console.log 'bot send error: ' + JSON.stringify json
          else if json.error_code == 403 then console.log 'bot send error: ' + JSON.stringify json
          else if json.error_code == 400 then console.log 'bot send error: ' + JSON.stringify json
          else throw 'unhandled bot send error: ' + JSON.stringify json
        else callback json

  sendDocumentAgain: (incoming, files, markup, callback) ->
    console.log 'sending document again'
    bot.sendDocumentAgain
      chat_id: incoming.chat.id
      reply_markup: markup
      document_id: files.document_id
      reply_to_message_id: incoming.message_id
      # files: {
      #   document: files.document
      # }
      (json) ->
        if json and json.ok == false
          if json.code == 'ECONNRESET'
            console.log 'bot send error: ' + JSON.stringify json
          else if json.error_code == 403 then console.log 'bot send error: ' + JSON.stringify json
          else if json.error_code == 400 then console.log 'bot send error: ' + JSON.stringify json
          else throw 'unhandled bot send error: ' + JSON.stringify json
        else callback json

randomlyAddRateAd = (incoming, msg) ->

  if incoming.show_store_ad == true or (incoming.show_store_ad == undefined and Math.floor(Math.random() * 5) == 0) # 20% chance to add
    msg += '\n\nIf you like this bot, please rate it at: https://telegram.me/storebot?start=' + botname.toLowerCase()

  return msg
  console.log bot.sendMessage
