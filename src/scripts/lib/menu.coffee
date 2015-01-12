$ = require 'jquery'


#
class Menu

  #
  constructor: (@$element) ->
    console.log @$element
    @$hamburger = @$element.find('.hamburger')
    @$pusher = @$element.find('.pusher')
    @init()

  #
  init: ->
    @$hamburger.on 'click', (evt) =>
      evt.stopPropagation()
      @$element.addClass('menu-open')
      @$pusher.one 'click', =>
        @$element.removeClass('menu-open')


module.exports = Menu
