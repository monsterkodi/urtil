Q        = require 'q'
fs       = require 'fs'
url      = require 'url'
del      = require 'del'
path     = require 'path'
_        = require 'lodash'
chalk    = require 'chalk'
mkpath   = require 'mkpath'
webshot  = require 'webshot'
process  = require 'process'
open     = require 'opn'
jade     = require 'jade'
stylus   = require 'stylus'
progress = require 'progress2'
noon     = require 'noon'
nomnom   = require 'nomnom'
resolve  = require './tools/resolve'
log      = require './tools/log'
err      = () -> 
    log chalk.bold.red [].slice.call(arguments).join ' '
    process.exit()

defaultTileWidth = 300
defaultTileHeight = 200
defaultScreenHeight = 1000

has = (ol, kv) -> 
    return false if not ol?
    if _.isArray ol
        kv in ol
    else 
        ol[kv]?

###
000   000   0000000   00     00
0000  000  000   000  000   000
000 0 000  000   000  000000000
000  0000  000   000  000 0 000
000   000   0000000   000   000
###

args = nomnom
   .script 'urtil'
   .options
      name:
         position: 0
         help: 'the name of the config file'
         list: false
         default: 'index'
         required: false
      inDir:      { abbr: 'i', default: './url', help: 'directory containing the url file'}
      outDir:     { abbr: 'o', default: './til', help: 'directory where the generated tiles are stored'}     
      screenHeight: { default: defaultScreenHeight, help: 'screen height'} 
      tileWidth:  { abbr: 'W', default: defaultTileWidth, help: 'tile width'}
      tileHeight: { abbr: 'H', default: defaultTileHeight, help: 'tile height'}
      tileSize:   { abbr: 'S', help: 'shortcut to set tile width and height (square tiles)'}
      timeout:    { abbr: 't', default: 60, help: 'maximal page retrieval time in seconds'}
      view:       { abbr: 'v', default: true, toggle: true, help: 'open generated page'}
      refresh:    { abbr: 'r',  help: 'force refresh of all tiles', flag: true}
      norefresh:  { abbr: 'n',  help: 'disable refresh of all tiles', flag: true}
      version:    { abbr: 'V',  help: 'output version', flag: true, hidden: true }
   .help chalk.blue("config file format:\n") + """
    \   <url>
    \       width    <w>
    \       height   <h>
    \t 
   """
   .parse()

if args.version
    log require("#{__dirname}/../package.json").version
    process.exit()

if args.tileSize?
    args.tileWidth = args.tileSize
    args.tileHeight = args.tileSize

###
000  000   000  000  000000000
000  0000  000  000     000   
000  000 0 000  000     000   
000  000  0000  000     000   
000  000   000  000     000   
###

indir  = resolve args.inDir
outdir = resolve args.outDir
name   = args.name

sites = "#{indir}/#{name}"
sites = "#{indir}/#{name}.noon" if not fs.existsSync sites
sites = "#{indir}/#{name}.crypt" if not fs.existsSync sites
if not fs.existsSync sites then err "config file with name #{chalk.yellow name} not found in #{chalk.yellow indir}!"

urls = noon.parse fs.readFileSync sites, encoding: 'utf8'

img  = "#{outdir}/.img/"
map  = {}
html = "#{outdir}/#{name}.html"

load = (f) ->
    try
        return fs.readFileSync f, encoding: 'utf8'        
    catch e
        err "can't read file", chalk.yellow f, chalk.magenta e
        process.exit -1

tiles = load path.join __dirname, '../jade/tiles.jade'
tile  = load path.join __dirname, '../jade/tile.jade'
styl  = load path.join __dirname, '../jade/tiles.styl'
styl  = _.template(styl) args
css   = stylus.render styl

if false
    del.sync img
    
mkpath.sync img

###
0000000     0000000   00000000 
000   000  000   000  000   000
0000000    000000000  0000000  
000   000  000   000  000   000
0000000    000   000  000   000
###

bar = new progress ":bar :current"+chalk.gray("/#{_.size urls}"),
    complete: chalk.bold.blue '█'
    incomplete: chalk.gray '█'
    width: 50
    total: _.size urls
bar.tick 0

###
0000000    000   000  000  000      0000000   
000   000  000   000  000  000      000   000 
0000000    000   000  000  000      000   000 
000   000  000   000  000  000      000   000 
0000000     0000000   000  0000000  0000000   
###

buildPage = ->

    t = tiles
    for u,i of map
        t += _.template(tile)
            href:   i.href
            img:    path.join(img, i.img)
            width:  args.tileWidth
            height: args.tileHeight
            
        if has urls[u], 'break'
            t += "        div.break\n"

    for i in [0..6]    
        t += "        span.site.empty\n"

    h = jade.render t, name:name, pretty:true

    r = _.template(h)(style: css)
            
    fs.writeFileSync html, r
    
    open html if args.view

###
000       0000000    0000000   0000000  
000      000   000  000   000  000   000
000      000   000  000000000  000   000
000      000   000  000   000  000   000
0000000   0000000   000   000  0000000  
###

load = (u) ->
    
    r = url.parse u
    r = url.parse("http://#{u}") unless r.hostname?
    f = path.join r.hostname + (r.path != '/' and r.path.replace(/\//g, '.') or '') + '.png'

    map[u] = 
        href: r.href
        img: f
    f = path.join img, f

    refresh = (has(urls[u], 'refresh') or args.refresh) and not args.norefresh
    fexists = fs.existsSync f
    if fexists and not refresh 
        bar.tick 1
        map[u].cached = true
        map[u].status = chalk.green 'ok'
        Q.fcall -> f
    else
        if fexists
            fs.renameSync f, path.join img, "."+map[u].img
        
        d = Q.defer()
        o = 
            windowSize:
                width: parseInt args.screenHeight * args.tileWidth / args.tileHeight
                height: args.screenHeight
            shotSize:
                width: 'window'
                height: 'window'
            defaultWhiteBackground: true
            
        webshot u, f, o, (e) ->
            bar.tick 1
            if e  
                map[u].status = chalk.red 'failed'
                d.reject new Error e
            else
                map[u].status = chalk.green 'ok'
                d.resolve f
        d.promise

###
 0000000   0000000   0000000   000   000
000       000       000   000  0000  000
0000000   000       000000000  000 0 000
     000  000       000   000  000  0000
0000000    0000000  000   000  000   000
###

if _.isArray urls
    l = ( load(u) for u in urls )
else
    l = ( load(u) for u of urls )

p = Q.allSettled l

Q.timeout p, args.timeout * 1000
    .fail -> 
        process.stdout.clearLine()
        process.stdout.cursorTo(0)
        log chalk.bold.yellow.bgRed '       timeout       '
    .then (results) -> 
        process.stdout.clearLine()
        process.stdout.cursorTo(0)
        for u,i of map
            f = path.join img, i.img
            c = path.join img, "."+i.img
            if not i.status?
                i.status = chalk.red 'timeout'
            if 'ok' != chalk.stripColor i.status
                if fs.existsSync c
                    fs.renameSync c, f
        log noon.stringify map, colors:true
        
        buildPage()
        
        process.exit()
