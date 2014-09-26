# dependencies
gulp =        require 'gulp'
less =        require 'gulp-less'
minifyCSS =   require 'gulp-minify-css'
notify =      require 'gulp-notify'
concat =      require 'gulp-concat'
imageMin =    require 'gulp-imagemin'
uglify =      require 'gulp-uglify'
coffee =      require 'gulp-coffee'
gulpIf =      require 'gulp-if'
fileInclude = require 'gulp-file-include'
runSequence = require 'run-sequence'
pngCrush =    require 'imagemin-pngcrush'
del =         require 'del'
streamQueue = require 'streamqueue'
yargs =       require 'yargs'
browserSync = require 'browser-sync'
svgSprite =   require 'gulp-svg-sprites'

# environment
PROD = yargs.argv.prod
DEV = !PROD

# paths
paths =
  src: 'src/'
  dist: 'dist/'
  bower: 'bower_components/'
  npm: 'node_modules/'



# BrowserSync
gulp.task 'browser-sync', ->
  browserSync
    server:
      baseDir: paths.dist
      directory: true
    port: 2000
    browser: 'google chrome'
    startPath: '/index.html'



# clean out dist folder
gulp.task 'clean', (done) ->
  del paths.dist, done



# compile LESS, combine with vendor CSS & minify
#   see: https://github.com/gulpjs/gulp/blob/master/docs/recipes/using-multiple-sources-in-one-task.md
gulp.task 'styles', ->
  streamBuild = streamQueue
    objectMode: true

  # vendor styles
  streamBuild.queue(
    gulp
      .src [
        "#{paths.npm}normalize.css/normalize.css"
        "#{paths.src}styles/vendor/main.css" # from HTML5 Boilerplate
      ]
  )

  # main styles
  streamBuild.queue(
    gulp
      .src "#{paths.src}styles/*.less"
      .pipe less()
  )

  # combine
  streamBuild.done()
    .pipe concat 'main.min.css'
    .pipe gulpIf PROD, minifyCSS()
    .pipe gulp.dest "#{paths.dist}styles/"
    .pipe gulpIf DEV, browserSync.reload
      stream: true



# concat & minify scripts
gulp.task 'scripts', ->
  streamBuild = streamQueue
    objectMode: true

  # javascript
  streamBuild.queue(
    gulp
      .src [
        "#{paths.npm}jquery/dist/jquery.js"
        "#{paths.npm}underscore/underscore.js"
        "#{paths.src}scripts/vendor/modernizr.js"
      ]
  )

  # coffeescript
  streamBuild.queue(
    gulp
      .src [
        "#{paths.src}scripts/lib/**/*.*"
        "#{paths.src}scripts/main.coffee"
      ]
      .pipe coffee()
  )

  # combine
  streamBuild.done()
    .pipe concat 'main.min.js'
    .pipe gulpIf PROD, uglify()
    .pipe gulp.dest "#{paths.dist}scripts/"
    .pipe gulpIf DEV, browserSync.reload
      stream: true



# compress images
#   see: https://github.com/sindresorhus/gulp-imagemin
gulp.task 'images', ->
  gulp
    .src "#{paths.src}images/*"
    .pipe imageMin
      progressive: true
      svgoPlugins: [
        {
          removeViewBox: false
        }
      ]
      use: [
        pngCrush()
      ]
    .pipe gulp.dest "#{paths.dist}images/"
    .pipe gulpIf DEV, browserSync.reload
      stream: true



# SVG icon sprite
#   see: http://css-tricks.com/svg-sprites-use-better-icon-fonts/
# TODO: set up PNG fallback (see: https://www.npmjs.org/package/gulp-svg-sprites)
gulp.task 'svg-icons', ->
  gulp
    .src "#{paths.src}icons/*.svg"
    .pipe svgSprite
      selector: 'icon-%f'
      preview: DEV and { sprite: 'index.html' } # TODO: file bug; setting not honored?
      mode: 'symbols'
    .pipe gulp.dest "#{paths.dist}icons/"



# copy HTML
gulp.task 'html', ['svg-icons'], ->
  gulp
    .src "#{paths.src}*.html"
    .pipe fileInclude
      basepath: paths.dist
    .pipe gulp.dest paths.dist
    .pipe browserSync.reload
      stream: true



# watch for changes
gulp.task 'watch', ->
  gulp.watch "#{paths.src}styles/**/*", ['styles']
  gulp.watch "#{paths.src}scripts/**/*", ['scripts']
  gulp.watch "#{paths.src}images/**/*", ['images']
  gulp.watch "#{paths.src}*.html", ['html']



# default task: call with 'gulp' on command line
gulp.task 'default', ->
  runSequence 'clean', ->
    if PROD
      gulp.start 'html', 'styles', 'scripts', 'images'
    else if DEV
      runSequence 'html', 'styles', 'scripts', 'images', ->
        gulp.start 'watch', 'browser-sync'
