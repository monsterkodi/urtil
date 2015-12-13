fs       = require 'fs'
path     = require 'path'
gulp     = require 'gulp'
jade     = require 'gulp-jade'
stylus   = require 'gulp-stylus'
gutil    = require 'gulp-util'
debug    = require 'gulp-debug'
plumber  = require 'gulp-plumber'
 
onError = (err) -> gutil.log err

gulp.task 'style', ->
    gulp.src 'style/*.styl', base: 'style'
        .pipe plumber()
        .pipe debug title: 'style'
        .pipe stylus()
        .pipe gulp.dest 'css'

gulp.task 'jade', ->
    gulp.src 'jade/*.jade', base: 'jade'
        .pipe plumber()
        .pipe debug title: 'jade'
        .pipe jade pretty: true
        .pipe gulp.dest '.'

gulp.task 'default', ->
                
    gulp.watch 'jade/*.jade', ['jade']
    gulp.watch 'style/*.styl', ['style']
