
Datastore = require "./DatabaseWrapper"
_ = require "underscore"
Equipment = require "../item/Equipment"
Q = require "q"
MessageCreator = require "./MessageCreator"
Constants = require "./Constants"
PetData = require "../../config/pets.json"
Pet = require "../character/npc/Pet"

class PetManager

  pets: []
  activePets: {}

  constructor: (@game) ->
    @db = new Datastore "pets", (db) ->
      db.ensureIndex { createdAt: 1 }, { unique: true }, ->

    @db.findForEach {}, @loadPet, @

    @DELAY_INTERVAL = 1000
    @beginGameLoop()

  beginGameLoop: ->
    setInterval =>
      arr = _.keys @activePets
      _.each arr, (player, i) =>
        pet = @activePets[player]
        setTimeout (pet.takeTurn.bind pet), @DELAY_INTERVAL/arr.length*i

    , @DELAY_INTERVAL

  getActivePetFor: (player) ->
    @activePets[player.identifier]

  createPet: (options) ->
    {player, type, name, attr1, attr2} = options

    options =
      name: name
      attrs: [attr1, attr2]
      type: type

      owner:
        identifier: player.identifier
        name: player.name

      creator:
        identifier: player.identifier
        name: player.name

    newPet = new Pet options
    @pets.push newPet
    newPet.petManager = @

    player.foundPets[type].purchaseDate = Date.now()
    @activePets[player.identifier]?.isActive = no
    @activePets[player.identifier] = newPet

  loadPet: (pet) ->
    pet.petManager = @
    @pets.push pet
    @activePets[pet.owner.identifier] = pet
    pet.__proto__ = Pet.prototype

    loadRN = (obj) ->
      return if not obj
      obj.__current = 0 if _.isNaN obj.__current
      obj.__proto__ = RestrictedNumber.prototype
      obj

    loadProfession = (professionName) ->
      new (require "../character/classes/#{professionName}")()

    loadEquipment = (equipment) ->
      _.forEach equipment, (item) ->
        item.__proto__ = Equipment.prototype

    _.forEach ['hp', 'mp', 'special', 'level', 'xp', 'gold'], (item) ->
      pet[item] = loadRN pet[item]

    pet.loadCalc()
    pet.equipment = loadEquipment pet.equipment
    pet.profession = loadProfession pet.professionName

  save: (pet) ->
    @db.update {createdAt: pet.createdAt}, pet, {upsert: yes}, (e) ->
      console.error "Pet save error: #{e}" if e

  getPetsForPlayer: (player) ->
    _.find @pets, {'owner.identifier': player.identifier}

  canUsePet: (pet, player) ->
    requirements = pet.requirements

    meets = yes

    _.each requirements.collectibles, (collectible) -> meets = no if not _.findWhere player.collectibles, {name: collectible}
    _.each requirements.achievements, (achievement) -> meets = no if not _.findWhere player.achievements, {name: achievement}
    _.each requirements.bosses,              (boss) -> meets = no if not (boss of player.statistics['calculated boss kills'])
    _.each (_.keys requirements.statistics), (stat) -> meets = no if player.statistics[stat] < requirements.statistics[stat]

    meets

  handlePetsForPlayer: (player) ->
    @checkPetAvailablity player

  checkPetAvailablity: (player) ->
    player.foundPets = {} if not player.foundPets
    for key,val of PetData
      continue if player.foundPets[key] or not @canUsePet val, player

      @game.eventHandler.broadcastEvent
        player: player
        sendMessage: yes
        type: "pet"
        message: "<player.name>#{player.name}</player.name> has unlocked a new pet: <player.name>#{key}</player.name>"

      player.foundPets[key] =
        cost: PetData[key].cost
        purchaseDate: null
        unlockDate: Date.now()

module.exports = exports = PetManager