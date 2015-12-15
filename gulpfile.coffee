fs     = require 'fs'
path   = require 'path'
gulp   = require 'gulp'
p      = require('gulp-load-plugins') lazy:false
(eval "#{k} = p.#{k}" for k,v of p)
 
onError = (err) -> util.log err

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

gulp.task 'build', ['jade', 'style']

gulp.task 'default', ->
                
    gulp.watch 'jade/*.jade', ['jade']
    gulp.watch 'style/*.styl', ['style']
