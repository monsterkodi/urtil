###
000       0000000    0000000 
000      000   000  000      
000      000   000  000  0000
000      000   000  000   000
0000000   0000000    0000000 
###

str  = require './str'
fs   = require 'fs'
pack = require '../../package.json'
name = pack.name
            
module.exports = -> 
    
    try
        if process.env['USER'] == 'kodi'
            msg = (str(a) for a in arguments).join(' ')
            fs.appendFileSync("/Users/kodi/s/#{name}/#{name}.log", msg+'\n', encoding: 'utf8')
            console.log msg
    catch
        console.log msg
