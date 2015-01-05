# dependencies
gulp        = require 'gulp'
less        = require 'gulp-less'
minifyCSS   = require 'gulp-minify-css'
notify      = require 'gulp-notify'
concat      = require 'gulp-concat'
imagemin    = require 'gulp-imagemin'
uglify      = require 'gulp-uglify'
coffee      = require 'gulp-coffee'
gulpIf      = require 'gulp-if'
fileInclude = require 'gulp-file-include'
gulpJade    = require 'gulp-jade'
jade        = require 'jade'
svgSprite   = require 'gulp-svg-sprites' # TODO: update to gulp-svg-sprite
frontMatter = require 'gulp-front-matter'
gulpsmith   = require 'gulpsmith'
markdown    = require 'metalsmith-markdown'
permalinks  = require 'metalsmith-permalinks'
templates   = require 'metalsmith-templates'
runSequence = require 'run-sequence'
pngcrush    = require 'imagemin-pngcrush'
del         = require 'del'
streamqueue = require 'streamqueue'
yargs       = require 'yargs'
browserSync = require 'browser-sync'
_           = require 'lodash'



# environment
PROD = yargs.argv.prod
DEV = !PROD



# paths
paths            = {}
paths.root       = '.'
paths.src        = "#{paths.root}/src"
paths.dist       = "#{paths.root}/dist"
paths.bower      = "#{paths.root}/bower_components"
paths.npm        = "#{paths.root}/node_modules"
paths.start      = "index.html" # entry point loaded in browser
paths.coffeelint = "coffeelint.json"



# BrowserSync
gulp.task 'browser-sync', ->
  browserSync
    server:
      baseDir: paths.dist
      directory: true
    port: 2000
    browser: 'google chrome'
    startPath: paths.start



# clean out dist folder
gulp.task 'clean', (done) ->
  del paths.dist, done



# copy root directory files (CNAME, robots.txt, etc.)
gulp.task 'root', ->
  gulp
    .src "#{paths.src}/root/**/*"
    .pipe gulp.dest paths.dist



# compile LESS, combine with vendor CSS & minify
#   see: https://github.com/gulpjs/gulp/blob/master/docs/recipes/using-multiple-sources-in-one-task.md
gulp.task 'styles', ->
  streamBuild = streamqueue
    objectMode: true

  # vendor styles
  streamBuild.queue(
    gulp
      .src [
        "#{paths.npm}/normalize.css/normalize.css"
        "#{paths.src}/styles/vendor/main.css" # from HTML5 Boilerplate
      ]
  )

  # main styles
  streamBuild.queue(
    gulp
      .src "#{paths.src}/styles/*.less"
      .pipe less()
  )

  # combine
  streamBuild.done()
    .pipe concat 'main.min.css'
    .pipe gulpIf PROD, minifyCSS()
    .pipe gulp.dest "#{paths.dist}/styles"
    .pipe gulpIf DEV, browserSync.reload
      stream: true



# concat & minify scripts
gulp.task 'scripts', ->
  streamBuild = streamqueue
    objectMode: true

  # javascript
  streamBuild.queue(
    gulp
      .src [
        "#{paths.npm}/jquery/dist/jquery.js"
        "#{paths.npm}/underscore/underscore.js"
        "#{paths.src}/scripts/vendor/modernizr.js"
      ]
  )

  # coffeescript
  streamBuild.queue(
    gulp
      .src [
        "#{paths.src}/scripts/lib/**/*.coffee"
        "#{paths.src}/scripts/main.coffee"
      ]
      .pipe coffee()
  )

  # combine
  streamBuild.done()
    .pipe concat 'main.min.js'
    .pipe gulpIf PROD, uglify()
    .pipe gulp.dest "#{paths.dist}/scripts"
    .pipe gulpIf DEV, browserSync.reload
      stream: true



# compress images
#   see: https://github.com/sindresorhus/gulp-imagemin
gulp.task 'images', ->
  gulp
    .src "#{paths.src}/images/*"
    .pipe imagemin
      progressive: true
      svgoPlugins: [
        {
          removeViewBox: false
        }
      ]
      use: [
        pngcrush()
      ]
    .pipe gulp.dest "#{paths.dist}/images"
    .pipe gulpIf DEV, browserSync.reload
      stream: true



# SVG icon sprite
#   see: http://css-tricks.com/svg-sprites-use-better-icon-fonts/
# TODO: set up PNG fallback (see: https://www.npmjs.org/package/gulp-svg-sprites)
gulp.task 'svg-icons', ->
  gulp
    .src "#{paths.src}/icons/*.svg"
    .pipe svgSprite
      selector: 'icon-%f'
      preview: DEV and { sprite: 'index.html' } # TODO: file bug; setting not honored?
      mode: 'symbols'
    .pipe gulp.dest "#{paths.dist}/icons"



# generate blog
gulp.task 'blog', ->
  gulp
    .src "#{paths.src}/posts/*.md"
    .pipe frontMatter()
    .on 'data', (file) ->
      _.assign file, file.frontMatter
      delete file.frontMatter
    .pipe gulpsmith()
      .use markdown()
      # .use permalinks()
      .use templates
        engine: 'jade'
        directory: "#{paths.src}/layouts"
    .pipe gulp.dest "#{paths.dist}/posts"



# copy HTML
gulp.task 'html', ['svg-icons'], ->
  gulp
    .src "#{paths.src}/*.jade"
    .pipe gulpJade()
    .pipe fileInclude
      basepath: paths.dist
    .pipe gulp.dest paths.dist
    .pipe gulpIf DEV, browserSync.reload
      stream: true



# watch for changes
gulp.task 'watch', ->
  gulp.watch "#{paths.src}/styles/**/*", ['styles']
  gulp.watch "#{paths.src}/scripts/**/*", ['scripts']
  gulp.watch "#{paths.src}/images/**/*", ['images']
  gulp.watch "#{paths.src}/posts/**/*", ['blog']
  gulp.watch [
    "#{paths.src}/*.jade"
    "#{paths.src}/icons/*.svg"
  ], ['html']



# default task: call with 'gulp' on command line
gulp.task 'default', ->
  runSequence 'clean', 'root', 'html', 'styles', 'scripts', 'images', 'blog', ->
    if DEV
      runSequence 'watch', 'browser-sync'
