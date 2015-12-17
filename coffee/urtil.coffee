
###
000   000  00000000   000000000  000  000    
000   000  000   000     000     000  000    
000   000  0000000       000     000  000    
000   000  000   000     000     000  000    
 0000000   000   000     000     000  0000000
###

fs       = require 'fs'
url      = require 'url'
rm       = require 'del'
sds      = require 'sds'
open     = require 'opn'
jade     = require 'jade'
noon     = require 'noon'
path     = require 'path'
chalk    = require 'chalk'
nomnom   = require 'nomnom'
stylus   = require 'stylus'
_        = require 'lodash'
mkpath   = require 'mkpath'
webshot  = require 'webshot'
process  = require 'process'
childp   = require 'child_process'
coffee   = require 'coffee-script'
resolve  = require './tools/resolve'
log      = require './tools/log'
err      = () -> 
    log chalk.bold.red [].slice.call(arguments).join ' '
    process.exit()

defaultTileWidth = 240
defaultTileHeight = 160
defaultScreenHeight = 1100

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
      inDir:        { abbr: 'i', default: '.',                  help: 'directory containing the config files'}
      outDir:       { abbr: 'd', default: '.',                  help: 'directory where the generated tiles are stored'}     
      tileWidth:    { abbr: 'W', default: defaultTileWidth,     help: 'tile width'}
      tileHeight:   { abbr: 'H', default: defaultTileHeight,    help: 'tile height'}
      tileSize:     { abbr: 'S',                                help: 'shortcut to set tile width and height (square tiles)'}
      bgColor:      {            default: '#ddd',               help: 'background color'} 
      fgColor:      {            default: '#000',               help: 'text color'} 
      screenHeight: {            default: defaultScreenHeight,  help: 'screen height'} 
      timeout:      { abbr: 't', default: 60,                   help: 'maximal page retrieval time in seconds'}
      open:         { abbr: 'o', default: true, toggle: true,   help: 'open generated page'}
      clean:        { abbr: 'c', default: true, toggle: true,   help: 'delete intermediate noon files'}
      quiet:        { abbr: 'q', flag: true,                    help: 'less verbose console output'}
      verbose:      { abbr: 'v', flag: true,                    help: 'verbose console output'}
      refresh:      { abbr: 'r', flag: true,                    help: 'force refresh of all tiles'}
      norefresh:    { abbr: 'n', flag: true,                    help: 'disable refresh of all tiles'}
      version:      { abbr: 'V', flag: true,                    help: 'output version', hidden: true }
      uplink:       { abbr: 'U', default: '',                   help: 'link to level up', hidden: true }
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

has = (ol, kv) -> 
    return false if not ol?
    if _.isArray ol
        kv in ol
    else 
        kv in Object.keys ol

set = (ol, kv, v=null) ->
    return if not ol?
    if _.isArray ol
        ol.push kv
    else
        ol[kv] = v

del = (ol, kv) ->
    return if not ol?
    if _.isArray ol
        _.pull ol, kv
    else
        delete ol[kv]
        
###
 0000000   000      000   0000000    0000000
000   000  000      000  000   000  000     
000000000  000      000  000000000  0000000 
000   000  000      000  000   000       000
000   000  0000000  000  000   000  0000000 
###
        
swapAlias = (ul) ->
    
    swp = (o, a, b) ->
        if has o, a
            set o, b, o[a]
            del o, a
            
    alias = [
        ['-',  'break']
        ['!',  'refresh']
        ['sh', 'screenHeight']
        ['th', 'tileHeight']
        ['tw', 'tileWidth']
        ['ts', 'tileSize']
        ['bg', 'bgColor']
        ['fg', 'fgColor']
        ['@',  'config']
    ]

    for u,v of ul
        for a in alias
            swp v, a[0], a[1]
    for a in alias
        swp ul, a[0], a[1]
    
swapAlias urls
    
if urls.config?
    for k in ['tileWidth', 'tileHeight', 'tileSize', 'bgColor', 'fgColor']
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

tiles  = load path.join __dirname, '../jade/tiles.jade'
tile   = load path.join __dirname, '../jade/tile.jade'
styl   = load path.join __dirname, '../jade/tiles.styl'
styl   = _.template(styl) args
css    = stylus.render styl
coff   = load path.join __dirname, '../jade/tiles.coffee'
coff   = _.template(coff) args
script = coffee.compile coff
    
mkpath.sync img

###
 0000000  000000000   0000000   000000000  000   000   0000000
000          000     000   000     000     000   000  000     
0000000      000     000000000     000     000   000  0000000 
     000     000     000   000     000     000   000       000
0000000      000     000   000     000      0000000   0000000 
###

status = ->
    return if args.quiet
    process.stdout.clearLine()
    process.stdout.cursorTo 0

    s = _.map urls, (v,u) -> 
        if not map[u]?.status? then chalk.gray '██'
        else if map[u].fixed then chalk.bold.yellow '██'
        else if map[u].cached then chalk.magenta '██'
        else if 'ok' == chalk.stripColor(map[u].status) 
            if map[u].local
                chalk.bold.white '██'
            else
                chalk.bold.green '██'
        else
            chalk.red.blue '██'
            
    s = '  ' + s.join ''
    c = process.stdout.getWindowSize()[0]
    while chalk.stripColor(s).length >= c
        s = s.substr 0, s.length-2
    console.log s

    process.stdout.cursorTo 0
    process.stdout.moveCursor 0, -1

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
            img:    path.join 'img', i.img
            width:  args.tileWidth
            height: args.tileHeight
            name:   _.last u.split '/'
            
        if has urls[u], 'break'
            t += "        div.break\n"
            breakLast = true
        else
            breakLast = false

    if not breakLast
        for i in [0...4]    
            t += "        span.site.empty\n"

    h = jade.render t, name:name, pretty:true

    r = _.template(h)(style: css, script:script)
                
    fs.writeFileSync html, r
    
    open html if args.open

###
000       0000000    0000000   0000000  
000      000   000  000   000  000   000
000      000   000  000000000  000   000
000      000   000  000   000  000   000
0000000   0000000   000   000  0000000  
###

load = (u, cb) ->
    
    local = u.indexOf('.') == -1
    if local
        us = "file://#{resolve path.join outdir, u + '.html'}" 
    else if not u.startsWith 'http'
        us = "http://#{u}" 
    else 
        us = u
     
    r = url.parse us

    map[u] = href: (local and "./#{u}.html" or r.href)
    map[u].local = true if local
    
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

        map[u].cached = true
        map[u].status = chalk.green 'ok'
        
        cb u
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

        if has urls[u], 'html'
            delete urls[u]['html']
            uc = _.clone urls[u]
            swapAlias uc
            delete uc['break']
            delete uc['refresh']
            delete uc['tileSize']
            delete uc['tileWidth']
            delete uc['tileHeight']
            delete uc['screenHeight']
            sds.save "#{u}.noon", uc
            cmd = "#{process.argv[0]} #{process.argv[1]} -o false -U ./#{name}.html #{u}.noon"
            if args.verbose   then cmd += " -v"
            if args.quiet   then cmd += " -q"
            if args.refresh then cmd += " -r"
            childp.execSync cmd,
                cwd: process.cwd()
                encoding: 'utf8'
                stdio: 'inherit'
            if args.clean
                rm.sync "#{u}.noon"
            console.log '' if not args.quiet

        sh = has(urls[u], 'screenHeight') and urls[u].screenHeight or args.screenHeight
        
        o = 
            windowSize:
                width: parseInt sh * args.tileWidth / args.tileHeight
                height: sh
            shotSize:
                width: 'window'
                height: 'window'
            defaultWhiteBackground: true
            
        webshot us, f, o, (e) =>
            if e  
                map[u].status = chalk.red 'failed'
            else
                map[u].status = chalk.green 'ok'
                
            cb u

###
 0000000   0000000   0000000   000   000
000       000       000   000  0000  000
0000000   000       000000000  000 0 000
     000  000       000   000  000  0000
0000000    0000000  000   000  000   000
###

if _.isEmpty urls
    buildPage()
    process.exit 0

numLoaded = 0
onLoaded = (u) -> 
    numLoaded += 1
    i = map[u]
    f = path.join img, i.img
    c = path.join img, "."+i.img
    if not i.status?
        i.status = chalk.red 'timeout'
    if 'ok' != chalk.stripColor i.status
        if fs.existsSync c
            fs.renameSync c, f
    if numLoaded == _.size urls
        if not args.quiet and args.verbose
            process.stdout.clearLine()
            process.stdout.cursorTo 0
            process.stdout.moveCursor 0, -1
            log noon.stringify map, colors:true
        buildPage()
        status()
        if args.uplink == '' and not args.quiet
            log ''
        process.exit 0
    else
        status()

if _.isArray urls
    l = ( load(u, onLoaded) for u in urls )
else
    l = ( load(u, onLoaded) for u of urls )

onTimeout = ->
    if not args.quiet
        if args.verbose
            process.stdout.clearLine()
            process.stdout.cursorTo 0
            process.stdout.moveCursor 0, -1
            log noon.stringify map, colors:true
        else
            process.stdout.clearLine()
            process.stdout.cursorTo 0
            process.stdout.moveCursor 0, -1
        log chalk.bold.yellow.bgRed '       timeout       '
        if args.uplink != ''
            buildPage()
        status()
        if args.uplink == ''
            log ''
    process.exit 0

setTimeout onTimeout, args.timeout * 1000
