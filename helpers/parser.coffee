module.exports =

  extractBaseCommand: (incoming, botname) ->

    if incoming.text.length > 256 then return ''

    incoming.botname = botname
    incoming.originaltext = incoming.text

    # console.log 'from ' + incoming.from.id + ' raw: ' + incoming.text

    isGroup = false
    isGroup = true if incoming.chat.title
    incoming.isGroup = isGroup
    isReply = true if incoming.reply_to_message

    if not incoming.text
      throw new Error('missing text: ' + JSON.stringify incoming)

    cmd = incoming.text.toLowerCase()

    reHelp = new RegExp('@' + botname + ' \/?help', 'i')
    reStart = new RegExp('@' + botname + ' \/?start', 'i')
    reSettings = new RegExp('@' + botname + ' \/?settings', 'i')

    if cmd == '/help@' + incoming.botname.toLowerCase() or reHelp.test(cmd)
      return 'help'
    if cmd == '/help' and incoming.isGroup then return ''

    if cmd == '/start@' + incoming.botname.toLowerCase() or reStart.test(cmd)
      return 'start'
    if cmd == '/start' and incoming.isGroup then return ''

    if cmd == '/settings@' + incoming.botname.toLowerCase() or reSettings.test(cmd)
      return 'settings'
    if cmd == '/settings' and incoming.isGroup then return ''

    cmd = incoming.text
	
    re = new RegExp('@' + botname, 'gi')
    if cmd.toLowerCase().indexOf('@' + botname.toLowerCase()) != -1 then cmd = cmd.replace(re, '').trim()
    #else if (isGroup and not isReply) then cmd = ''

    console.log cmd
	
    return cmd
