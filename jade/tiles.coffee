
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
        name?.style.display = 'block'

onMouseOut = (event) ->
    if 'site' in event.target.classList 
        tile = tileForElement event.target
        name = tile?.getElementsByClassName('name')[0]
        name?.style.display = 'none'

window.onload = () ->
    document.addEventListener 'click', onClick
    if "<%= uplink %>".length
        document.getElementById('stage').style.cursor = 'n-resize'
        
    document.addEventListener 'mouseover', onMouseOver
    document.addEventListener 'mouseout',  onMouseOut
