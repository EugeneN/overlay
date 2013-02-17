excludeArgs = (fn, num) -> _handler = (args...) -> fn args[num...]

makeUniqueInt = -> new Date().getTime()

makeUniqueId = -> "id#{makeUniqueInt()}"

getJNodeId = (jnode) ->
    id = jnode.attr 'id'

    unless id
        id = makeUniqueId()
        jnode.attr 'id', id

    id


EVENT =
    LOADED: 'olayLoaded'
    CLOSED: 'olayClosed'

DEFAULT =
    mask: null
    top: null
    closeOnEsc: true
    closeOnMask: true
    closeSel: null
    loaderCls: null
    showOnLoad: true
    onLoad: undefined
    onClose: undefined
    triggerSel: null
    lazy:
        ev: null
        cb: undefined

# IDs of the fully finished overlays.
OVERLAYS = []


calcTop = (olay) ->
    height = olay.outerHeight()

    # Gone beyond the lower border.
    if height > screen.availHeight
        10 # min top param

    # Centered in the visible.
    else
        (screen.availHeight - height) / 2

storeOlayId = (id) -> OVERLAYS.push id

olayStored = (id) -> id in OVERLAYS

hideOlay = (id) ->
    olay = jQuery "##{id}"
    olay.css 'display', 'none'
    olay.trigger EVENT.CLOSED, id

showOlay = (id) -> (jQuery "##{id}").css 'display', 'block'


methods = (olayId) ->
    body = jQuery document.body
    olay = jQuery "##{olayId}"
    olayStyle =
        'position': 'absolute'
    wrapperStyle =
        'position': 'fixed'
        'top': 0
        'left': 0
        'overflow-y': 'auto'
        'overflow-x': 'hidden'
        'width': screen.width

    # Order is important.
    _makeWrapper: ->
        body.css 'overflow', 'hidden'
        wrapper = (jQuery "<div>").appendTo(body).append(olay)

        wrapperHeight = if olay.outerHeight() > screen.availHeight
            olay.outerHeight()
        else
            screen.availHeight

        (wrapper.css prop, val) for prop, val of wrapperStyle
        wrapper.css 'height', wrapperHeight

    onLoad: (fn) ->
        unless jQuery.isFunction fn
            return null

        olay.bind EVENT.LOADED, (excludeArgs fn, 1)

    onClose: (fn) ->
        unless jQuery.isFunction fn
            return null

        olay.bind EVENT.CLOSED, (excludeArgs fn, 1)

    trigger: (sel) -> (jQuery sel).bind 'click', -> showOlay olayId

    loaderCls: (opts) -> console.log ">>> loaderCls"

    lazy: (opts) -> console.log ">>> lazy"

    closeOnEsc: (bool) ->
        unless bool
            return null

        _handleKeyUp = (ev) ->
            unless ev.which is 27 # key escape
                return null

            # Hide top overlay.
            hideOlay OVERLAYS.reverse()[OVERLAYS.length - 1]

        body.bind 'keyup', _handleKeyUp

    showOnLoad: (bool) ->
        fn = if bool then showOlay else hideOlay
        olay.bind EVENT.LOADED, -> fn olayId

    mask: (opts) -> console.log ">>> mask"

    closeOnMask: (bool) ->
        unless bool
            return true

        mask = null
        # mask.click -> hideOlay olayId

    closeSel: (sel) -> (jQuery sel).bind 'click', -> hideOlay olayId

    top: (val) -> olayStyle.top = val or calcTop olay

    _afterLoad: ->
        (olay.css prop, val) for prop, val of olayStyle
        olay.css 'left', (screen.width - olay.outerWidth()) / 2

        olay.trigger EVENT.LOADED, olayId


# Entry point.
# jQuery, maintaining chainability.
overlay = (opts) ->
    opts = jQuery.extend DEFAULT, opts

    @.each (idx, el) ->
        jnode = jQuery el

        jnodeId = getJNodeId jnode
        if olayStored jnodeId
            return jnode

        storeOlayId jnodeId
        # Execute methods with the received options.
        (fn opts[name]) for name, fn of (methods jnodeId)

jQuery.fn.overlay = overlay
