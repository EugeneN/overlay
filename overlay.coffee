excludeArgs = (fn, num) -> _handler = (args...) -> fn args[num...]...

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

# Objects of the fully finished overlays.
OVERLAYS = {}


getMaxZIndex = ->
    zIndexes = (o.zIndex for i, o of OVERLAYS)
    maxZIndex = Math.max zIndexes...

    if maxZIndex > 0 then maxZIndex else 5000

calcTop = (olay) ->
    height = olay.outerHeight()

    # Gone beyond the lower border.
    if height > screen.availHeight
        10 # min top param

    # Centered in the visible.
    else
        (screen.availHeight - height) / 2

storeOlayId = (id, opts) -> OVERLAYS[id] = opts

olayStored = (id) -> id of OVERLAYS

storeWrapper = (olayId, wrapper) -> OVERLAYS[olayId].wrapper = wrapper

getWrapper = (olayId) -> OVERLAYS[olayId].wrapper

storeMask = (olayId, mask) -> OVERLAYS[olayId].mask = mask

getMask = (olayId) -> OVERLAYS[olayId].mask

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

        wrapper.css prop, val for prop, val of wrapperStyle
        wrapper.css 'height', wrapperHeight
        storeWrapper olayId, wrapper

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
            ids = (i for i, o of OVERLAYS)
            hideOlay ids.reverse()[ids.length - 1]

        body.bind 'keyup', _handleKeyUp

    showOnLoad: (bool) ->
        fn = if bool then showOlay else hideOlay
        olay.bind EVENT.LOADED, -> fn olayId

    # Mask can be either an object or a parameter
    #   if the mask is a value, it is assumed that the value is a background-color
    #   css style otherwise, if the mask is an object, then the object key
    #   is style property, and the value of the object is css value.
    mask: (opts) ->
        mask = jQuery "<div>"
        wrapper = getWrapper olayId
        zIndex = getMaxZIndex()
        width = wrapper.outerWidth()
        height = wrapper.outerHeight()

        if jQuery.isPlainObject opts
            for style, value of opts
                if style is 'color' then style = 'background-color'
                mask.css style, value

            (mask.css 'opacity', 0.8) unless opts.opacity

        else
            mask.css('background-color', opts).css('opacity', 0.8)

        mask.css('position', 'fixed').css('z-index', zIndex).css('left', 0).css('top', 0)
            .css('width', width).css('height', height)

        storeMask olayId, mask
        wrapper.append mask

    closeOnMask: (bool) ->
        unless bool
            return true

        mask = null
        # mask.click -> hideOlay olayId

    closeSel: (sel) -> (jQuery sel).bind 'click', -> hideOlay olayId

    top: (val) -> olayStyle.top = val or calcTop olay

    _afterLoad: ->
        olay.css prop, val for prop, val of olayStyle

        olay.css('left', (screen.width - olay.outerWidth()) / 2)
            .css('z-index', getMaxZIndex() + 1)
            .trigger EVENT.LOADED, olayId


# Entry point.
# jQuery, maintaining chainability.
overlay = (opts) ->
    opts = jQuery.extend DEFAULT, opts

    @.each (idx, el) ->
        jnode = jQuery el

        jnodeId = getJNodeId jnode
        if olayStored jnodeId
            return jnode

        storeOlayId jnodeId, opts
        # Execute methods with the received options.
        (fn opts[name]) for name, fn of (methods jnodeId)

jQuery.fn.overlay = overlay
