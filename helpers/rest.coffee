http = require 'http'
https = require 'https'
http.post = require 'http-post'

module.exports =

  GET: (options, callback) ->
    if options.https
      _get https, options, callback
    else
      _get http, options, callback

  POST: (url, callback) ->
    if options.https
      _post https, options, callback
    else
      _post http, options, callback






_get = (method, options, callback) ->
  req = method.get options, (response) ->
    body = ''
    response.on 'data', (data) -> body += data
    response.on 'end', () -> callback body, response

  req.setTimeout 10000, ->
    req.end()
    throw new Error('request timed out: ' + JSON.stringify options)

_post = (method, options, callback) ->
  req = method.post options, (response) ->
    body = ''
    response.on 'data', (data) -> body += data
    response.on 'end', () -> callback body, response

  req.setTimeout 10000, ->
    req.end()
    throw new Error('request timed out: ' + JSON.stringify options)
