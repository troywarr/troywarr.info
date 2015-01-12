GoogleAnalytics = require './lib/google-analytics'
Menu            = require './lib/menu'
$               = require 'jquery'


# Google Analytics
analytics = new GoogleAnalytics('UA-55183285-1')
analytics.init()

# slide-in menu
menu = new Menu($('main'))
