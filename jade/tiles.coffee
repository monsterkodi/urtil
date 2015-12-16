
onClick = (event) ->
    if event.target.id == 'stage'
        window.location.href = "<%= uplink %>"

window.onload = () ->
    document.addEventListener 'click', onClick
    if "<%= uplink %>".length
        document.getElementById('stage').style.cursor = 'n-resize'
