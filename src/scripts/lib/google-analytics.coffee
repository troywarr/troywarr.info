# load analytics.js and set up page tracking
#   see: http://www.ignoredbydinosaurs.com/2014/09/deconstructing-the-google-analytics-tag
class GoogleAnalytics

  constructor: ->
    window.GoogleAnalyticsObject = 'ga'
    window.ga =
      q: []
      l: +new Date()

  trackPageview: ->
    window.ga 'create', 'UA-55183285-1', 'auto'
    window.ga 'send', 'pageview'

  init: =>
    $.ajax
      url: '//www.google-analytics.com/analytics.js'
      dataType: 'script'
      cache: true # see: http://davidwalsh.name/loading-scripts-jquery
    .done @trackPageview



# register
(window.troyWarr ?= {}).GoogleAnalytics = GoogleAnalytics
