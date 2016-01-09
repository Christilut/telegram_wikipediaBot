DEBUG = false

TelegramBot = require './helpers/node-telegram-bot'
restHelper = require './helpers/rest'
collectionHelper = require './helpers/collection'
parser = require './helpers/parser'
db = require 'mongoose'
telegram = require './helpers/telegram'
statHelper = require './helpers/statistics'

botname = 'WikipediaRobot'
token = process.argv[2]

if not token
  console.log 'First argument must be bot token'
  process.exit()

statHelpCalled = 'help called'
statSearchMultiple = 'multiple results served'
statSearchSingle = 'single result served'
statSearchNone = 'no results found'

buttontextChangeLanguage = 'Change default Wikipedia language'
buttontextCancel = 'Cancel'

labelSayLanguageCode = 'Please say the language code you would like to set as default. For example: DE, FA or SV.'

User = db.model 'User', { user_id: Number, username: String, first_name: String, last_name: String, default_language: String, awaiting_language: {type: Boolean, default: false }, time_created: { type: Date, default: Date.now } }

db.connect 'mongodb://localhost/WikipediaBot', (err) ->
  if err then throw err

  statHelper.initDb db,
    statHelpCalled,
    statSearchMultiple,
    statSearchSingle,
    statSearchNone


# From: https://meta.wikimedia.org/wiki/List_of_Wikipedias
# codes = '';
# $("a[title$=':']").each(function (i, e) { codes += e.text + ': \'\', ' });
# console.log(codes);
validLanguageCodes = {
  en: true, sv: true, de: true, nl: true, fr: true, war: true, ru: true, ceb: true, it: true, es: true, vi: true, pl: true, ja: true, pt: true,
  zh: true, uk: true, ca: true, fa: true, no: true, sh: true, fi: true, ar: true, id: true, ro: true, hu: true, cs: true, sr: true, ko: true,
  ms: true, tr: true, min: true, eo: true, kk: true, eu: true, da: true, sk: true, bg: true, he: true, hy: true, lt: true, hr: true, sl: true,
  et: true, uz: true, gl: true, nn: true, vo: true, la: true, simple: true, el: true, hi: true, ce: true, az: true, ka: true, th: true, be: true,
  oc: true, mk: true, mg: true, ur: true, new: true, ta: true, tt: true, cy: true, pms: true, tl: true, bs: true, lv: true, te: true,
  'be-x-old': true, br: true, ht: true, sq: true, jv: true, lb: true, mr: true, is: true, ml: true, 'zh-yue': true, bn: true, af: true, ga: true,
  ba: true, pnb: true, cv: true, tg: true, fy: true, sco: true, lmo: true, ky: true, my: true, yo: true, an: true, sw: true, ne: true, ast: true,
  io: true, gu: true, scn: true, bpy: true, nds: true, ku: true, als: true, qu: true, su: true, 'zh-min-nan': true, pa: true, kn: true, ckb: true,
  mn: true, ia: true, nap: true, arz: true, 'bat-smg': true, bug: true, wa: true, gd: true, am: true, 'map-bms': true, bar: true, yi: true, mzn: true,
  si: true, fo: true, nah: true, vec: true, sah: true, os: true, sa: true, mrj: true, hsb: true, li: true, 'roa-tara': true, or: true, pam: true,
  mhr: true, se: true, mi: true, ilo: true, bcl: true, hif: true, gan: true, ps: true, rue: true, glk: true, 'nds-nl': true, bo: true, vls: true,
  diq: true, bh: true, 'fiu-vro': true, xmf: true, co: true, tk: true, sc: true, gv: true, km: true, hak: true, csb: true, vep: true, kv: true,
  lrc: true, zea: true, crh: true, frr: true, 'zh-classical': true, eml: true, ay: true, wuu: true, udm: true, stq: true, kw: true, nrm: true,
  rm: true, szl: true, as: true, so: true, koi: true, lad: true, fur: true, mt: true, sd: true, ie: true, gn: true, dv: true, dsb: true, pcd: true,
  lij: true, 'cbk-zam': true, cdo: true, ksh: true, ext: true, gag: true, mwl: true, ang: true, ug: true, ace: true, lez: true, pi: true, pag: true,
  nv: true, frp: true, sn: true, kab: true, myv: true, ln: true, pfl: true, xal: true, krc: true, haw: true, rw: true, pdc: true, kaa: true, to: true,
  kl: true, arc: true, nov: true, kbd: true, av: true, bxr: true, lo: true, bjn: true, ha: true, tet: true, tpi: true, pap: true, na: true, lbe: true,
  jbo: true, ty: true, tyv: true, 'roa-rup': true, mdf: true, wo: true, ig: true, srn: true, nso: true, za: true, kg: true, ab: true, ltg: true,
  zu: true, om: true, chy: true, cu: true, rmy: true, tw: true, mai: true, tn: true, chr: true, pih: true, bi: true, got: true, sm: true, ss: true,
  mo: true, rn: true, ki: true, pnt: true, xh: true, bm: true, iu: true, ee: true, gom: true, ak: true, lg: true, ts: true, ks: true, fj: true,
  ik: true, st: true, sg: true, ff: true, dz: true, ny: true, ch: true, ti: true, ve: true, tum: true, cr: true, ng: true, cho: true, kj: true,
  mh: true, ho: true, ii: true, aa: true, mus: true, hz: true, kr: true, nan: true, 'zh-min-nan': true, cz: true, cs: true, dk: true, da: true,
  als: true, ak: true
}

search = (incoming, cmd) ->
  if DEBUG then console.log 'search requested: ' + cmd

  if cmd.indexOf('wiki') == 0 then cmd = cmd.substring('wiki'.length).trim()

  languageCode = 'en'

  # retrieve languagecode from db if user set it
  User.find { user_id: incoming.from.id }, (err, result) ->
    if err then throw err

    if result[0] then languageCode = result[0].default_language

    languageRegex = new RegExp(':[^\\s]+', 'i')
    languageCodeMatch = cmd.match languageRegex

    if languageCodeMatch
      languageCode = languageCodeMatch[0][1..].toLowerCase().trim()
      cmd = cmd.replace(languageRegex, '').trim()
      if DEBUG then console.log 'cmd without language code: ' + cmd
      if DEBUG then console.log 'changed to language code: ' + languageCode

    if not validLanguageCodes[languageCode]
      incoming.show_store_ad = false
      return telegram.textPersonal incoming, 'That language code does not exist. See https://meta.wikimedia.org/wiki/List_of_Wikipedias for all valid codes.'

    if not cmd
      incoming.show_store_ad = false
      return telegram.textPersonal incoming, 'Enter a search term. For example: /wiki avatar'

    ambiguous = false
    if cmd.indexOf(' (wiki)') != -1 and cmd.indexOf(' (wiki)') == cmd.length - ' (wiki)'.length then ambiguous = true

    if ambiguous then cmd = cmd.substring(0, cmd.indexOf(' (wiki)'))

    cmd = encodeURI cmd

    options = {
      host: languageCode + '.wikipedia.org'
      path: '/w/api.php?action=opensearch&search=' + cmd
      https: true
    }

    if DEBUG then console.log 'GET: ' + options.host + options.path

    restHelper.GET options, (body) ->

      json = JSON.parse body

      # remove duplicates from array case insensitive
      if json[1]
        json[1] = json[1].filter(collectionHelper.uniqueCaseInsensitive)

      # console.log json[1]

      if not json[1] or json[1].length == 0
        msgOut = 'Sorry, Wikipedia had no results...'

        incoming.show_store_ad = false

        telegram.textPersonal incoming, msgOut
        statHelper.addOne statSearchNone

      else if json[1].length == 1 or ambiguous
        summary = ''
        url = ''

        if ambiguous
          for i in [0..json[1].length - 1]
            if encodeURI(json[1][i]) == cmd
              summary = json[2][i]
              url = json[3][i]
              break
        else
          summary = json[2][0]
          url = json[3][0]

        if not summary and not url then throw new Error('summary and url empty: ' + cmd)

        if incoming.originaltext then cmd = incoming.originaltext

        if ambiguous then cmd = cmd.substring(0, cmd.indexOf(' (wiki)'))

        msgTitle = cmd.replace /^wiki:?\w* /, ''
        msgOut = ''#'Wikipedia - ' + msgTitle + '\n\n'

        if not summary
          msgOut += 'No summary found.'
        else
          msgOut += summary

        msgOut += '\n\n' + url

        if languageCode != 'en' then msgOut += '\n\nNEW: set your default language with /settings'

        if DEBUG then console.log 'found single result for: ' + cmd
        statHelper.addOne statSearchSingle

        telegram.textPersonal incoming, msgOut

      else if json[1].length > 1
        if DEBUG then console.log 'multiple results found for: ' + cmd
        statHelper.addOne statSearchMultiple

        buttons = []
        for t in [0..json[1].length - 1]
          topic = json[1][t]

          if encodeURI(topic.toLowerCase()) == cmd.toLowerCase() then topic += ' (wiki)'

          if not incoming.isGroup then topic = 'wiki:' + languageCode + ' ' + topic

          lastChar = json[2][t].charAt(json[2][t].length - 1)
          if lastChar != ':'  # avoid 'This page may refer to:' pages
            buttons.push topic

        incoming.show_store_ad = false

        telegram.textPersonalKeyboardList incoming, 'Wikipedia (' + languageCode.toUpperCase() + ') - Multiple results, please pick one...', buttons

confirmChangeLanguage = (incoming, cmd) ->
  languageCode = cmd.substring(cmd.indexOf(' ') + 1).toLowerCase()

  incoming.show_store_ad = false

  if DEBUG then console.log 'changing language to: ' + languageCode

  if not validLanguageCodes[languageCode]
    return telegram.textPersonal incoming, 'That language code does not exist. See https://meta.wikimedia.org/wiki/List_of_Wikipedias for all valid codes.'

  User.find { user_id: incoming.from.id }, (err, result) ->
    if err then throw err

    if result[0]
      result[0].default_language = languageCode
      result[0].awaiting_language = false

      result[0].save (err) ->
        if err then throw err
        if DEBUG then console.log 'updated user language to: ' + languageCode

        return telegram.textPersonal incoming, 'Your /wiki searches will now all be /wiki:' + languageCode + ' searches.'


    else
      newUser = new User {
        user_id: incoming.from.id
        username: incoming.from.username
        first_name: incoming.from.first_name
        last_name: incoming.from.last_name
        default_language: languageCode
      }

      newUser.save (err) ->
        if err then throw err

        if DEBUG then console.log 'set user language to: ' + languageCode

        return telegram.textPersonal incoming, 'Your /wiki searches will now all be /wiki:' + languageCode + ' searches.'

changeLanguage = (incoming) ->
  incoming.show_store_ad = false

  telegram.textPersonalKeyboardList incoming, labelSayLanguageCode, [buttontextCancel], { force_reply: true, resize_keyboard: true }

  if not incoming.isGroup
    User.find { user_id: incoming.from.id }, (err, result) ->
      if err then throw err

      if result[0]
        result[0].awaiting_language = true

        result[0].save (err) ->
          if err then throw err

      else
        newUser = new User {
          user_id: incoming.from.id
          username: incoming.from.username
          first_name: incoming.from.first_name
          last_name: incoming.from.last_name
          awaiting_language: true
        }

        newUser.save (err) ->
          if err then throw err

          if DEBUG then console.log 'awaiting language code...'

settings = (incoming) ->
  if DEBUG then console.log 'search settings requested'

  incoming.show_store_ad = false

  telegram.textPersonalKeyboardList incoming, 'Please pick an option in the keyboard.', [buttontextChangeLanguage, buttontextCancel], { resize_keyboard: true }

help = (incoming) ->
  if DEBUG then console.log 'search help requested'
  statHelper.addOne statHelpCalled

  incoming.show_store_ad = false

  telegram.textPersonal incoming,
  'Unofficial Wikipedia bot\n
  \n
  This bot searches Wikipedia for you and returns the result.\n
  \n
  Commands:\n
  /help - Shows the help\n
  /wiki - Searches Wikipedia\n
  \n
  Append a language code to search in that Wikipedia. Full list of codes can be found here: https://meta.wikimedia.org/wiki/List_of_Wikipedias\n
  You can change your default language with /settings.\n
  \n
  For example:\n
  /wiki Futurama\n
  /wiki Star Trek\n
  /wiki:nl Amsterdam\n
  /wiki:fa لپ تاپ\n
  /wiki:zh 笔记本电脑'

processMessage = (incoming) ->

  if not incoming.text then return # only process messages, not chat state updates

  cmd = parser.extractBaseCommand(incoming, botname)
  
  if DEBUG then console.log incoming
  
  reply = undefined
  if incoming.reply_to_message and cmd.indexOf('/') != 0
    reply = incoming.reply_to_message.text
    match = reply.match /^Wikipedia \((\w*)\)/

  if reply and match
    # if cmd.indexOf('/wiki') == 0 then cmd = cmd.substring('/wiki'.length).trim()
    languageCode = match[1]
    cmd = ':' + languageCode.toLowerCase() + ' ' + cmd

  if cmd.indexOf('/') == 0 then cmd = cmd.substring(1)

  if DEBUG then console.log cmd

  if cmd.indexOf('wiki') == 0 or (reply and reply.indexOf('Multiple results, please pick one...') != -1)
    search incoming, cmd
  else if reply == labelSayLanguageCode and cmd != buttontextCancel # for groups, the easy way
    confirmChangeLanguage incoming, cmd
  else if not incoming.isGroup and validLanguageCodes[cmd.toLowerCase()] == true # for nongroup, the hard way..
    User.find { user_id: incoming.from.id }, (err, result) ->
      if err then throw err

      if result.length > 0 and result[0].awaiting_language
        confirmChangeLanguage incoming, cmd
  else
    switch cmd
      when 'help', 'start'
        help incoming
      when 'settings'
        settings incoming
      when buttontextCancel
        incoming.show_store_ad = false
        telegram.textPersonal incoming, 'No changes were made.'
      when buttontextChangeLanguage
        changeLanguage incoming
      else
        if DEBUG then console.log 'unhandled: ' + cmd


console.log botname + ' started...'

bot = new TelegramBot { token: token }
telegram.setBot(bot, botname)

bot.on 'message', (incoming) ->
  processMessage incoming

bot.start()
