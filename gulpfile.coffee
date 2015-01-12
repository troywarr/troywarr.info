# dependencies
gulp        = require 'gulp'
less        = require 'gulp-less'
minifyCSS   = require 'gulp-minify-css'
notify      = require 'gulp-notify'
rename      = require 'gulp-rename'
imagemin    = require 'gulp-imagemin'
uglify      = require 'gulp-uglify'
gulpIf      = require 'gulp-if'
fileInclude = require 'gulp-file-include'
gulpJade    = require 'gulp-jade'
gutil       = require 'gulp-util'
plumber     = require 'gulp-plumber'
svgSprite   = require 'gulp-svg-sprite'
frontMatter = require 'gulp-front-matter'
filesize    = require 'gulp-filesize'
gulpsmith   = require 'gulpsmith'
jade        = require 'jade'
collections = require 'metalsmith-collections'
markdown    = require 'metalsmith-markdown'
permalinks  = require 'metalsmith-permalinks'
templates   = require 'metalsmith-templates'
pngcrush    = require 'imagemin-pngcrush'
del         = require 'del'
browserSync = require 'browser-sync'
browserify  = require 'browserify'
transform   = require 'vinyl-transform'
_           = require 'lodash'


# environment shortcuts
PROD = gutil.env.prod
DEV  = !PROD


# paths
paths       = {}
paths.base  = '.'
paths.src   = "#{paths.base}/src"
paths.dist  = "#{paths.base}/dist"
paths.bower = "#{paths.base}/bower_components"
paths.npm   = "#{paths.base}/node_modules"
paths.start = "index.html" # entry point loaded in browser


# error handling
handleError = (err) ->
  notify.onError(
    title: 'Gulp Error'
    message: "#{err.message}"
  )(err)
  @emit 'end'


# BrowserSync
gulp.task 'browser-sync', ->
  browserSync
    server:
      baseDir: paths.dist
      directory: true
    port: 2000
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
  del "#{paths.dist}/styles/**/*.*", done


# clean 'scripts' task output
gulp.task 'clean:scripts', (done) ->
  del "#{paths.dist}/scripts/**/*.*", done


# clean 'images' task output
gulp.task 'clean:images', (done) ->
  del "#{paths.dist}/images/**/*.*", done


# clean 'blog' task output
gulp.task 'clean:blog', (done) ->
  del "#{paths.dist}/blog/**/*.*", done


# clean 'icons' task output
gulp.task 'clean:icons', (done) ->
  del "#{paths.dist}/icons/**/*.*", done


# copy root directory files (CNAME, robots.txt, etc.)
gulp.task 'root', ['clean:root'], ->
  gulp
    .src "#{paths.src}/root/**/*.*"
    .pipe gulp.dest paths.dist


# compile LESS & minify
gulp.task 'styles', ['clean:styles'], ->
  gulp
    .src "#{paths.src}/styles/*.less"
    .pipe plumber handleError
    .pipe less()
    .pipe rename 'main.min.css'
    .pipe gulpIf PROD, minifyCSS()
    .pipe gulp.dest "#{paths.dist}/styles"
    .pipe gulpIf DEV, browserSync.reload
      stream: true


# compile, bundle and minify scripts
#   see: https://medium.com/@sogko/gulp-browserify-the-gulp-y-way-bb359b3f9623
gulp.task 'scripts', ['clean:scripts'], ->
  browserified = transform(
    (filename) ->
      browserify
        entries: filename
        extensions: ['.coffee']
        debug: true
      .bundle()
  )
  gulp
    .src "#{paths.src}/scripts/index.coffee"
    .pipe plumber handleError
    .pipe browserified
    .pipe gulpIf PROD, uglify()
    .pipe rename
      extname: '.min.js'
    .pipe gulp.dest "#{paths.dist}/scripts"
    .pipe filesize()


# compress images
#   see: https://github.com/sindresorhus/gulp-imagemin
gulp.task 'images', ['clean:images'], ->
  gulp
    .src "#{paths.src}/images/*.*"
    .pipe plumber handleError
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


# SVG icon sprite
#   see: http://css-tricks.com/svg-sprites-use-better-icon-fonts/
gulp.task 'icons', ['clean:icons'], ->
  gulp
    .src "#{paths.src}/icons/**/*.svg"
    .pipe plumber handleError
    .pipe svgSprite
      shape:
        id:
          generator: 'icon-'
      mode:
        symbol:
          inline: true
          example: DEV and { dest: 'example/icons.html' }
          dest: 'svg'
          sprite: 'icons.svg'
    .pipe gulp.dest paths.dist


# generate blog (Metalsmith)
gulp.task 'blog', ['clean:blog'], ->
  gulp
    .src [
      'index.md'
      'posts/*.md'
    ], { cwd: "#{paths.src}/**" }
    # .pipe plumber handleError # TODO: why does this suppress blog output?
    .pipe frontMatter()
    .on 'data', (file) ->
      _.assign file, file.frontMatter
      delete file.frontMatter
    .pipe gulpsmith()
      .use collections
        pages:
          pattern: 'index.md'
        posts:
          pattern: 'posts/*.md'
          sortBy: 'date'
          reverse: true
      .use markdown()
      .use permalinks
        pattern: ':title'
      .use templates
        engine: 'jade'
        directory: "#{paths.src}/templates"
        self: true
    .pipe gulp.dest "#{paths.dist}/blog"


# render & copy HTML
gulp.task 'html', ['clean:html', 'icons'], ->
  gulp
    .src "#{paths.src}/pages/*.jade"
    .pipe plumber handleError
    .pipe gulpJade()
    .pipe fileInclude
      basepath: paths.dist
    .pipe gulp.dest paths.dist


# development build & watch
gulp.task 'dev', ['root', 'html', 'styles', 'scripts', 'images', 'blog'], ->
  gulp.run 'browser-sync' # run after everything is compiled
  gulp.watch "#{paths.src}/styles/**/*.less", ['styles', browserSync.reload]
  gulp.watch "#{paths.src}/scripts/**/*.coffee", ['scripts', browserSync.reload]
  gulp.watch "#{paths.src}/images/**/*.*", ['images', browserSync.reload]
  gulp.watch [
    "#{paths.src}/posts/**/*.md"
    "#{paths.src}/templates/**/*.jade"
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
