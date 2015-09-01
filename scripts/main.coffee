# Description:
#   Hubot script for getting info from kegbot
#
# Dependencies:
#   None
#
# Configuration:
#   HUBOT_KEGBOT_URL
#   HUBOT_KEGBOT_TOKEN
#
# Commands:
#   hubot what( beers are|'s) on tap? - shows the current beers on tap
#   hubot what( beers are|'s) on deck? - shows the beers on deck
#
# Notes:
#   None
#
# Author:
#   ml10

module.exports = (robot) ->
  unless process.env.HUBOT_KEGBOT_URL?
    robot.logger.error 'HUBOT_KEGBOT_URL not set!'
    return

  unless process.env.HUBOT_KEGBOT_TOKEN?
    robot.logger.error 'HUBOT_KEGBOT_TOKEN not set!'
    return

  robot.respond /what( beers are|'s) on tap?/i, (res) ->
    get_current_taps res   

  robot.respond /what( beers are|'s) on deck?/i, (res) ->
    get_kegs_on_deck res   

get_current_taps = (message) ->
  taps = process.env.HUBOT_KEGBOT_URL + '/api/taps/'
  message.http(taps)
    .headers('X-Kegbot-Api-Key': process.env.HUBOT_KEGBOT_TOKEN)
    .get() (error, response, body) ->
      data = JSON.parse(body)
      messages = []
      try
        for tap in data.objects
          tapLocation = if tap.name == 'RIGHT' then 'Right' else 'Left'
          remaining = Math.round(tap.current_keg.percent_full)
          msg = "The #{tapLocation} tap has #{tap.current_keg.beverage.name}"
          if tap.current_keg.type?.abv && tap.current_keg.type.abv > 0
            msg = msg + " (#{tap.current_keg.type.abv}% ABV)"
          if tap.current_keg.beverage?.style
            msg = msg + " a #{tap.current_keg.beverage?.style}"
          if tap.current_keg.beverage?.producer?.name
            msg = msg + " by #{tap.current_keg.beverage?.producer?.name}"
          msg = msg + " with #{remaining}% remaining."
          messages.push(msg)
        if messages.length > 0
          message.send messages.join("\n")
        else
          message.send "Nothing's is on tap right now, sorry. Better head to Bockwinkle's to fend for yourself."
      catch error
        console.log('Uncaught error: ' + error)
        robot.logger.error 'Uncaught error: ' + error

get_kegs_on_deck = (message) ->   
  ondeck = process.env.HUBOT_KEGBOT_URL + '/api/kegs/'
  message.http(ondeck)
    .headers('X-Kegbot-Api-Key': process.env.HUBOT_KEGBOT_TOKEN)
    .get() (error, response, body) ->
      data = JSON.parse(body)
      onDeck = (keg for keg in data.objects when keg.percent_full == 100 && !keg.online)
      messages = []
      try
        for keg in onDeck
          messages.push(keg.beverage.name)
        if messages.length > 0
          message.send messages.join("\n")
        else
          message.send 'No taps on deck, please drink slowly.'
      catch error
        console.log('Uncaught error: ' + error)
        robot.logger.error 'Uncaught error: ' + error
