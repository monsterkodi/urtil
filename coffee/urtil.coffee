Q        = require 'q'
fs       = require 'fs'
url      = require 'url'
del      = require 'del'
sds      = require 'sds'
noon     = require 'noon'
path     = require 'path'
_        = require 'lodash'
chalk    = require 'chalk'
mkpath   = require 'mkpath'
webshot  = require 'webshot'
process  = require 'process'
child_process = require 'child_process'
open     = require 'opn'
jade     = require 'jade'
stylus   = require 'stylus'
progress = require 'progress2'
nomnom   = require 'nomnom'
resolve  = require './tools/resolve'
log      = require './tools/log'
err      = () -> 
    log chalk.bold.red [].slice.call(arguments).join ' '
    process.exit()

defaultTileWidth = 240
defaultTileHeight = 160
defaultScreenHeight = 1100

has = (ol, kv) -> 
    return false if not ol?
    if _.isArray ol
        kv in ol
    else 
        kv in Object.keys ol

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
      inDir:      { abbr: 'i', default: '.', help: 'directory containing the config files'}
      outDir:     { abbr: 'o', default: '.', help: 'directory where the generated tiles are stored'}     
      tileWidth:  { abbr: 'W', default: defaultTileWidth, help: 'tile width'}
      tileHeight: { abbr: 'H', default: defaultTileHeight, help: 'tile height'}
      tileSize:   { abbr: 'S', help: 'shortcut to set tile width and height (square tiles)'}
      screenHeight: { default: defaultScreenHeight, help: 'screen height'} 
      bgColor:    { default: '#ddd', help: 'background color'} 
      timeout:    { abbr: 't', default: 60, help: 'maximal page retrieval time in seconds'}
      view:       { abbr: 'v', default: true, toggle: true, help: 'open generated page'}
      progress:   { abbr: 'p', default: true, toggle: true, help: 'display progress bar'}
      quiet:      { abbr: 'q', flag: true, help: 'less verbose console output'}
      refresh:    { abbr: 'r', flag: true, help: 'force refresh of all tiles'}
      norefresh:  { abbr: 'n', flag: true, help: 'disable refresh of all tiles'}
      version:    { abbr: 'V', flag: true, help: 'output version', hidden: true }
   .parse()

if args.version
    log require("#{__dirname}/../package.json").version
    process.exit()

###
000  000   000  000  000000000
000  0000  000  000     000   
000  000 0 000  000     000   
000  000  0000  000     000   
000  000   000  000     000   
###

indir  = resolve args.inDir
outdir = resolve args.outDir
name   = path.basename args.name, path.extname args.name
sites  = resolve "#{indir}/#{args.name}"

if not fs.existsSync(sites) or fs.statSync(sites).isDirectory()
    for ext in sds.extensions
        sites = resolve "#{indir}/#{name}.#{ext}"
        if fs.existsSync sites
            break
sites = "#{indir}/#{name}.crypt" if not fs.existsSync sites
if not fs.existsSync sites then err "config file with name #{chalk.yellow name} not found in #{chalk.yellow indir}!"

urls = sds.load sites

if urls['@']?
    urls.config = urls['@']
    delete urls['@']
    
if urls.config?
    for k in ['tileWidth', 'tileHeight', 'tileSize', 'bgColor']
        args[k] = urls.config[k] if urls.config[k]?
    delete urls['config']

if args.tileSize?
    args.tileWidth = args.tileSize
    args.tileHeight = args.tileSize

if _.isEmpty(urls) and not args.bgColor == "#ddd"
    err "config file seems to be empty!", noon.stringify urls

img  = resolve "#{outdir}/img/"
map  = {}
html = resolve "#{outdir}/#{name}.html"

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
    
mkpath.sync img

###
0000000     0000000   00000000 
000   000  000   000  000   000
0000000    000000000  0000000  
000   000  000   000  000   000
0000000    000   000  000   000
###

if not _.isEmpty(urls) and args.progress
    bar = new progress ":bar :current"+chalk.gray("/#{_.size urls}"),
        complete: chalk.bold.blue '█'
        incomplete: chalk.gray '█'
        width: 48
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
    breakLast = false
    for u,i of map
        t += _.template(tile)
            href:   i.href
            img:    path.join('img', i.img)
            width:  args.tileWidth
            height: args.tileHeight
            
        if has urls[u], 'break'
            t += "        div.break\n"
            breakLast = true
        else
            breakLast = false

    if not breakLast
        for i in [0...4]    
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
    
    local = u.indexOf('.') == -1
    if local
        us = "file://#{resolve path.join outdir, u + '.html'}" 
    else if not u.startsWith 'http'
        us = "http://#{u}" 
    else 
        us = u
     
    r = url.parse us

    map[u] = href: (local and "./#{u}.html" or r.href)
    
    if has urls[u], 'image'
        f = urls[u].image
        map[u].fixed = true
    else if local
        f = "#{u}.png"
    else
        p = r.path != '/' and r.path.replace(/\//g, '.') or ''
        p = p.replace /[~]/g, '_'
        f = path.join r.hostname + p + '.png'

    map[u].img = "#{f}"
            
    f = resolve path.join img, f

    refresh = has urls[u], 'refresh'
    refresh = true  if args.refresh
    refresh = false if args.norefresh or map[u].fixed
    
    fexists = fs.existsSync f

    if fexists and not refresh 
        bar?.tick 1
        map[u].cached = true
        map[u].status = chalk.green 'ok'
        Q.fcall -> f
    else
        if fexists
            fs.renameSync f, path.join img, "."+map[u].img
            
        ###
        000   000  000000000  00     00  000    
        000   000     000     000   000  000    
        000000000     000     000000000  000    
        000   000     000     000 0 000  000    
        000   000     000     000   000  0000000
        ###
        # if has urls[u], 'html'
        #     delete urls[u]['html']
        #     sds.save "#{u}.noon", urls[u]
        #     console.log 'saved', new String child_process.execSync "cat #{u}.noon"
        #     # cmd = "#{process.argv[1]} -q -p 0 -v 0 #{u}.noon"
        #     # log cmd
        #     # log process.cwd()
        #     # log child_process.spawnSync process.argv[0], [process.argv[1], '-q', '-p', '0', '-v', '0', "#{u}.noon"]
        #     # log child_process.execSync cmd,
        #     log child_process.execFileSync process.argv[1], ['-q', '-p', '0', '-v', '0', "#{u}.noon"],
        #         cwd: process.cwd()
        #         encoding: 'utf8'
        #         shell: '/usr/local/bin/bash'

        sh = has(urls[u], 'screenHeight') and urls[u].screenHeight or args.screenHeight
        
        d = Q.defer()
        o = 
            windowSize:
                width: parseInt sh * args.tileWidth / args.tileHeight
                height: sh
            shotSize:
                width: 'window'
                height: 'window'
            defaultWhiteBackground: true
            
        webshot us, f, o, (e) ->
            bar?.tick 1
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

        if not args.quiet
            log noon.stringify map, colors:true

        buildPage()
        
        if args.quiet
            log 'done'
        process.exit 0
