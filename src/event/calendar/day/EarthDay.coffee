
TimePeriod = require "../../TimePeriod"

`/**
  * The Earth day increases all elemental stats.
  *
  * @name Earth Day
  * @effect +25 fire
  * @effect +3% fire
  * @effect +25 ice
  * @effect +3% ice
  * @effect +25 earth
  * @effect +3% earth
  * @effect +25 water
  * @effect +3% water
  * @effect +25 thunder
  * @effect +3% thunder
  * @category Day
  * @package Calendar
*/`
class EarthDay extends TimePeriod

  constructor: ->
  
  @dateName = "Day of the Earth"
  @desc = "Boost to all elemental magic"

  @fire: -> 25
  @firePercent: -> 3
  @ice: -> 25
  @icePercent: -> 3
  @earth: -> 25
  @earthPercent: -> 3
  @water: -> 25
  @waterPercent: -> 3
  @thunder: -> 25
  @thunderPercent: -> 3

module.exports = exports = EarthDay