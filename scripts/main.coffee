# Description:
#   Hubot script for getting info from kegbot
#
# Dependencies:
#   None
#
# Configuration:
#   HUBOT_KEGBOT_URL - the kegbot url to target
#   HUBOT_KEGBOT_TOKEN - a kegbot API token
#
# Commands:
#   hubot what( beers are|'s) on tap? - shows the current beers on tap
#   hubot what( beers are|'s) on deck? - shows the beers on deck
#
# Author:
#   https://github.com/ml10

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

get_taps = (message) ->
  taps = process.env.HUBOT_KEGBOT_URL + '/api/taps/'
  message.http(taps)
    .headers('X-Kegbot-Api-Key': process.env.HUBOT_KEGBOT_TOKEN)
    .get() (error, response, body) ->
      data = JSON.parse(body)
      msg = [] 
      try
        for tap in data.objects
          msg.push("Tap #{tap.id}: #{tap.current_keg.beverage.name}")
        message.send msg.join("\n")
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
      msg = [] 
      try
        for keg in onDeck
          msg.push(keg.beverage.name)
        message.send msg.join("\n")
      catch error
        console.log('Uncaught error: ' + error)
        robot.logger.error 'Uncaught error: ' + error
