fs       = require 'fs'
del      = require 'del'
sds      = require 'sds'
path     = require 'path'
copy     = require 'copy'
chalk    = require 'chalk'
gulp     = require 'gulp'
plumber  = require 'gulp-plumber'
coffee   = require 'gulp-coffee'
pepper   = require 'gulp-pepper'
salt     = require 'gulp-salt'
gutil    = require 'gulp-util'
debug    = require 'gulp-debug'
bump     = require 'gulp-bump'
template = require 'gulp-template'
 
onError = (err) -> gutil.log err

gulp.task 'coffee', ->
    gulp.src ['coffee/**/*.coffee'], base: 'coffee'
        .pipe plumber()
        .pipe pepper
            stringify: (info) -> '"'+ chalk.blue.bold(info.class) + chalk.blue(info.type) + chalk.magenta.bold(info.method) + chalk.blue(' ►') + '"'
            paprikaInfix: (s) -> chalk.red s
        .pipe debug title: 'coffee'        
        .pipe coffee(bare: true).on('error', onError)
        .pipe gulp.dest 'js'

gulp.task 'coffee_release', ->
    gulp.src ['coffee/**/*.coffee'], base: './coffee'
        .pipe pepper
            stringify: (info) -> '""'
            paprika: 
                dbg: 'log'
        .pipe coffee(bare: true).on('error', onError)
        .pipe gulp.dest 'js'
    
gulp.task 'salt', ->
    gulp.src ['coffee/**/*.coffee', 'jade/*.styl'], base: '.'
        .pipe plumber()
        .pipe salt()
        .pipe gulp.dest '.'

gulp.task 'bump', ->
    gulp.src './package.json'
        .pipe bump()
        .pipe gulp.dest '.'
        
gulp.task 'build', ['clean', 'coffee'], ->
gulp.task 'release', ['clean', 'bump', 'coffee_release'], ->
        
gulp.task 'clean', (c) ->
    del ['js']
    c()

gulp.task 'default', ->
                
    gulp.watch [ 'coffee/**/*.coffee', 'jade/*.styl' ], ['salt']
