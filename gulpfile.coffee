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
gutil       = require 'gulp-util'
jade        = require 'jade'
svgSprite   = require 'gulp-svg-sprites' # TODO: update to gulp-svg-sprite
frontMatter = require 'gulp-front-matter'
gulpsmith   = require 'gulpsmith'
collections = require 'metalsmith-collections'
markdown    = require 'metalsmith-markdown'
permalinks  = require 'metalsmith-permalinks'
templates   = require 'metalsmith-templates'
pngcrush    = require 'imagemin-pngcrush'
del         = require 'del'
streamqueue = require 'streamqueue'
browserSync = require 'browser-sync'
_           = require 'lodash'


# environment shortcuts
PROD = gutil.env.debug
DEV  = !PROD


# paths
paths            = {}
paths.base       = '.'
paths.src        = "#{paths.base}/src"
paths.dist       = "#{paths.base}/dist"
paths.bower      = "#{paths.base}/bower_components"
paths.npm        = "#{paths.base}/node_modules"
paths.start      = "index.html" # entry point loaded in browser


# BrowserSync
gulp.task 'browser-sync', ->
  browserSync
    server:
      baseDir: paths.dist
      directory: true
    port: 2000
    browser: 'google chrome'
    startPath: paths.start


# delete entire dist folder
gulp.task 'clean', (done) ->
  del paths.dist, done


# clean 'root' task output
gulp.task 'clean:root', (done) ->
  del [
    "#{paths.dist}/CNAME"
    "#{paths.dist}/robots.txt"
  ], done


# clean 'html' task output
gulp.task 'clean:html', (done) ->
  del "#{paths.dist}/*.html", done


# clean 'styles' task output
gulp.task 'clean:styles', (done) ->
  del "#{paths.dist}/styles/**/*", done


# clean 'scripts' task output
gulp.task 'clean:scripts', (done) ->
  del "#{paths.dist}/scripts/**/*", done


# clean 'images' task output
gulp.task 'clean:images', (done) ->
  del "#{paths.dist}/images/**/*", done


# clean 'blog' task output
gulp.task 'clean:blog', (done) ->
  del "#{paths.dist}/blog/**/*", done


# clean 'icons' task output
gulp.task 'clean:icons', (done) ->
  del "#{paths.dist}/icons/**/*", done


# copy root directory files (CNAME, robots.txt, etc.)
gulp.task 'root', ['clean:root'], ->
  gulp
    .src "#{paths.src}/root/**/*"
    .pipe gulp.dest paths.dist


# compile LESS, combine with vendor CSS & minify
#   see: https://github.com/gulpjs/gulp/blob/master/docs/recipes/using-multiple-sources-in-one-task.md
gulp.task 'styles', ['clean:styles'], ->
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
gulp.task 'scripts', ['clean:scripts'], ->
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


# compress images
#   see: https://github.com/sindresorhus/gulp-imagemin
gulp.task 'images', ['clean:images'], ->
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


# SVG icons
#   see: http://css-tricks.com/svg-sprites-use-better-icon-fonts/
# TODO: set up PNG fallback (see: https://www.npmjs.org/package/gulp-svg-sprites)
gulp.task 'icons', ['clean:icons'], ->
  gulp
    .src "#{paths.src}/icons/*.svg"
    .pipe svgSprite
      selector: 'icon-%f'
      preview: DEV and { sprite: 'index.html' } # TODO: file bug; setting not honored?
      mode: 'symbols'
    .pipe gulp.dest "#{paths.dist}/icons"


# generate blog
gulp.task 'blog', ['clean:blog'], ->
  gulp
    .src [
      'posts/*.md'
      'index.md'
    ], { cwd: "#{paths.src}/**" }
    .pipe frontMatter()
    .on 'data', (file) ->
      _.assign file, file.frontMatter
      delete file.frontMatter
    .pipe gulpsmith()
      .use collections
        pages:
          pattern: 'index.md'
        posts:
          pattern: '*.md'
          sortBy: 'date'
          reverse: true
      .use markdown()
      .use permalinks
        pattern: ':title'
      .use templates
        engine: 'jade'
        directory: "#{paths.src}/layouts"
        self: true
    .pipe gulp.dest "#{paths.dist}/blog"


# copy HTML
gulp.task 'html', ['clean:html', 'icons'], ->
  gulp
    .src "#{paths.src}/*.jade"
    .pipe gulpJade()
    .pipe fileInclude
      basepath: paths.dist
    .pipe gulp.dest paths.dist


# development build & watch
gulp.task 'dev', ['root', 'html', 'styles', 'scripts', 'images', 'blog', 'browser-sync'], ->
  gulp.watch "#{paths.src}/styles/**/*", ['styles', browserSync.reload]
  gulp.watch "#{paths.src}/scripts/**/*", ['scripts', browserSync.reload]
  gulp.watch "#{paths.src}/images/**/*", ['images', browserSync.reload]
  gulp.watch [
    "#{paths.src}/posts/**/*.md"
    "#{paths.src}/layouts/**/*.jade"
    "#{paths.src}/index.md"
  ], ['blog', browserSync.reload]
  gulp.watch [
    "#{paths.src}/*.jade"
    "#{paths.src}/icons/*.svg"
  ], ['html', browserSync.reload]


# production build
gulp.task 'prod', ['root', 'html', 'styles', 'scripts', 'images', 'blog'], ->


# build: call with 'gulp build' on command line
#   use 'gulp build --prod' to prepare assets for production use (minify, etc.)
gulp.task 'build', ['clean'], ->
  gulp.run 'prod'


# develop: call with 'gulp' on command line
gulp.task 'default', ['clean'], ->
  gulp.run 'dev'
