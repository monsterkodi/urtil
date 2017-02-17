
tileForElement = (e) ->
    if not e? then return null
    if 'tile' in e.classList
        e
    else
        tileForElement e.parentElement

onClick = (event) ->
    if event.target.id == 'stage' or 'empty' in event.target.classList
        window.location.href = "<%= uplink %>"

onMouseOver = (event) ->
    if 'site' in event.target.classList 
        tile = tileForElement event.target
        name = tile?.getElementsByClassName('name')[0]
        overStyle = "unset"
        overStyle = "none" if "off" in name.classList
        name?.style.display = overStyle

onMouseOut = (event) ->
    if 'site' in event.target.classList 
        tile = tileForElement event.target
        name = tile?.getElementsByClassName('name')[0]
        outStyle = "none"
        outStyle = "unset" if "on" in name.classList
        name?.style.display = outStyle

tiles = -> [].slice.call document.body.getElementsByClassName('site tile')

select = (t) ->
    list = document.body.getElementsByClassName('site link')
    list[t].focus()

tab = (d) ->
    tile = tileForElement document.activeElement
    list = tiles()
    tileIndex = list.indexOf tile
    select (list.length+tileIndex+d) % list.length
        
down = ->
    tile = tileForElement document.activeElement
    if not tile?
        select 0
        return

    list = tiles()
    tileIndex = list.indexOf tile
    tr = tile.getBoundingClientRect()
    
    for t in [tileIndex+1...list.length]
        return if t >= list.length
        tt = list[t]
        ttr = tt.getBoundingClientRect()
        if ttr.top > tr.top
            ntr = list[t+1]?.getBoundingClientRect()
            while ntr? and ntr.top == ttr.top and ntr.left <= tr.left
                t += 1
                ntr = list[t+1]?.getBoundingClientRect()
            select t
            return

up = ->
    tile = tileForElement document.activeElement
    if not tile?
        select 0
        return

    list = tiles()
    tileIndex = list.indexOf tile
    tr = tile.getBoundingClientRect()

    for t in [(tileIndex-1)..0]
        return if t < 0
        tt = list[t]
        ttr = tt.getBoundingClientRect()
        if ttr.top < tr.top
            ntr = list[t-1]?.getBoundingClientRect()
            while ntr? and ntr.top == ttr.top and ntr.right >= tr.right
                t -= 1
                ntr = list[t-1]?.getBoundingClientRect()
            select t
            return

onKeyDown = (event) ->
    switch event.keyCode
        when 38
            up()
        when 37
            tab -1
        when 39
            tab 1
        when 40
            down()

window.onload = () ->
    document.addEventListener 'click', onClick
    if "<%= uplink %>".length
        document.getElementById('stage').style.cursor = 'n-resize'
        
    document.addEventListener 'mouseover', onMouseOver
    document.addEventListener 'mouseout',  onMouseOut
    document.addEventListener 'keydown',   onKeyDown
    select 0
