makeUniqueInt = -> new Date().getTime()

makeUniqueId = -> "id#{makeUniqueInt()}"

getJNodeId = (jnode) ->
    id = jnode.attr 'id'

    unless id
        id = makeUniqueId()
        jnode.attr 'id', id

    id


EVENT =
    REMOVE:    'olayRemove'
    RECTOP:    'olayRecalcTop'
    ATTACHLDR: 'olayAttachLoader'
    REMOVELDR: 'olayRemoveLoader'

    LOADED:    'olayLoaded'
    CLOSED:    'olayClosed'

DEFAULT =
    mask: null
    top: null
    closeOnEsc: true
    closeOnMask: true
    closeSel: null
    showOnLoad: true
    onLoad: undefined
    onClose: undefined
    triggerSel: null
    removeOnClose: false
    lazy:
        ev: null
        cb: undefined
        loaderCls: null

# Objects of the fully finished overlays.
OVERLAYS = {}
BODY = jQuery document.body
# Global state :( to optimize the speed.
_COUNT = 0


getMaxZIndex = ->
    zIndexes = (o.zIndex or 5000 for i, o of OVERLAYS)
    Math.max zIndexes...

storeZIndex = (id, idx) -> OVERLAYS[id].zIndex = idx

calcTop = (id) ->
    height = (jQuery "##{id}").outerHeight()
    vpHeight = window.innerHeight

    # Gone beyond the lower border.
    if height > vpHeight - 20 # beauty number
        10 # min top param

    # Centered in the visible.
    else
        (vpHeight - height) / 2

storeOlayId = (id, opts) -> OVERLAYS[id] = opts

olayStored = (id) -> id of OVERLAYS

storeWrapper = (olayId, wrapper) -> OVERLAYS[olayId].wrapper = wrapper

getWrapper = (olayId) -> OVERLAYS[olayId].wrapper

storeMask = (olayId, mask) -> OVERLAYS[olayId].mask = mask

getMask = (olayId) -> OVERLAYS[olayId].mask

totalRecalc = ->
    vpHeight = window.innerHeight
    vpWidth = window.innerWidth

    ids = (i for i, _ of OVERLAYS)
    # Recalculate top params.
    ids.map (id) ->
        olay = jQuery "##{id}"
        top = OVERLAYS[id].top or calcTop id
        left = (vpWidth - olay.outerWidth()) / 2
        olay.css('top', top).css('left', left)

    # Recalculate wrapper and mask size.
    wps = ((getWrapper i) for i, _ of OVERLAYS)
    wps.map (wp) -> wp.css('height', vpHeight).css('width', vpWidth)

    # Optimization. All wrappers has the same width and height, so we can take
    #   on any wrapper and extract his inner width.
    iw = wps[0][0].scrollWidth if wps[0]

    masks = ((getMask i) for i, _ of OVERLAYS)
    masks.map (msk) -> msk.css('height', vpHeight).css('width', iw)

removeOlay = (id) ->
    olay = jQuery "##{id}"

    events = (e for k, e of EVENT)
    events.map (ev) -> olay.unbind ev

    (getWrapper id).remove()
    _COUNT -= 1
    delete OVERLAYS[id]

hideOlay = (id) ->
    (BODY.css 'overflow', 'auto') if _COUNT is 1
    (getWrapper id).hide()
    removeLoader()
    (jQuery "##{id}").trigger EVENT.CLOSED, id

showOlay = (id) ->
    BODY.css 'overflow', 'hidden'
    (getWrapper id).show()

attachLoader = (id, loaderCls) ->
    olay = jQuery "##{id}"
    loader = jQuery '<div>', {'class': loaderCls}

    # create mask element
    mask = jQuery '<div/>', {'id': 'js-overlay-loader'}
    mask.css('top', olay.offset().top).css('left', olay.offset().left)
        .css('width', olay.outerWidth()).css('height', olay.outerHeight())
        .css('z-index', getMaxZIndex()).css('position', 'fixed').append(loader)

    # Center the loader vertically.
    overlayHeight = olay.outerHeight()
    loaderHeight = loader.outerHeight() or overlayHeight # default at top
    loaderTop = (overlayHeight - loaderHeight) / 2

    loader.css('position', 'relative').css('top', loaderTop)
    BODY.append mask

removeLoader = -> (jQuery "#js-overlay-loader").remove()


impl = (olayId) ->
    olay = jQuery "##{olayId}"

    olayStyle =
        'position': 'absolute'

    wrapperStyle =
        'position': 'fixed'
        'top': 0
        'left': 0
        'overflow-y': 'auto'
        'overflow-x': 'hidden'
        'z-index': getMaxZIndex()


    _makeWrapper = ->
        BODY.css 'overflow', 'hidden'
        wrapper = (jQuery "<div>").appendTo(BODY).append(olay)

        wrapper.css prop, val for prop, val of wrapperStyle
        storeWrapper olayId, wrapper

    onLoad = (fn) ->
        unless jQuery.isFunction fn
            return null

        olay.bind EVENT.LOADED, (_, id) -> fn id

    onClose = (fn) ->
        unless jQuery.isFunction fn
            return null

        olay.bind EVENT.CLOSED, (_, id) -> fn id

    trigger = (sel) -> (jQuery sel).bind 'click', -> showOlay olayId

    closeOnEsc = (bool) ->
        unless bool
            return null

        _handleKeyUp = (ev) ->
            unless ev.which is 27 # key escape
                return null

            # Hide top overlay.
            ids = (i for i, o of OVERLAYS)
            hideOlay ids.reverse()[_COUNT - 1] if _COUNT > 0

        BODY.bind 'keyup', _handleKeyUp

    showOnLoad = (bool) ->
        fn = if bool then showOlay else hideOlay
        olay.bind EVENT.LOADED, -> fn olayId

    # Mask can be either an object or a parameter
    #   if the mask is a value, it is assumed that the value is a background-color
    #   css style otherwise, if the mask is an object, then the object key
    #   is style property, and the value of the object is css value.
    mask = (opts) ->
        return true unless opts
        mask = jQuery "<div style='position: fixed; left: 0; top: 0;'></div>"

        if jQuery.isPlainObject opts
            for style, value of opts
                if style is 'color' then style = 'background-color'
                mask.css style, value

            (mask.css 'opacity', 0.8) unless opts.opacity

        else
            mask.css('background-color', opts).css('opacity', 0.8)

        mask.css 'z-index', getMaxZIndex()

        storeMask olayId, mask
        (getWrapper olayId).append mask

    closeOnMask = (bool) ->
        mask = getMask olayId
        return true unless bool and mask

        opacity = mask.css 'opacity'

        _mouseenter = -> mask.fadeTo(120, 0.95).css('cursor', 'pointer')

        _mouseout = ->
            mask.fadeTo(180, opacity).css('cursor', 'default') if mask.is ":visible"

        mask.click -> hideOlay olayId
        mask.hover _mouseenter, _mouseout

    closeSel = (sel) -> olay.on 'click', sel, -> hideOlay olayId

    removeOnClose = (bool) -> (olay.bind EVENT.CLOSED, -> removeOlay olayId) if bool

    _afterLoad = ->
        olay.css prop, val for prop, val of olayStyle
        zIndex = storeZIndex olayId, getMaxZIndex() + 1

        olay.css('z-index', zIndex)
            .trigger(EVENT.LOADED, olayId)
            .bind(EVENT.REMOVE, -> removeOlay olayId)
            .bind(EVENT.ATTACHLDR, -> console.log ">>> attach loader", olayId)
            .bind(EVENT.REMOVELDR, -> console.log ">>> remove loader", olayId)

        totalRecalc()
        _COUNT += 1

    lazy = ({ev, cb, loaderCls}={opts}) ->
        return true unless ev and cb

        process_cb = (ev, args...) ->
            removeLoader()
            cb olayId, args...

            # At this stage overlay already loaded and we should call
            # `LOADED` event
            olay.trigger EVENT.LOADED, olayId

            # Unbind recieved event.
            olay.unbind ev
            totalRecalc()

        attachLoader olayId, loaderCls
        olay.bind ev, process_cb

    # Order is important.
    {_makeWrapper, onLoad, onClose, trigger, closeOnEsc, showOnLoad, mask,
    closeOnMask, closeSel, removeOnClose, _afterLoad, lazy}


# Entry point.
# jQuery, maintaining chainability.
overlay = (opts) ->
    opts = jQuery.extend {}, DEFAULT, opts

    @.each (idx, el) ->
        jnode = jQuery el

        jnodeId = getJNodeId jnode
        if olayStored jnodeId
            return jnode

        storeOlayId jnodeId, opts
        # Execute methods with the received options.
        (fn opts[name]) for name, fn of (impl jnodeId)

jQuery.fn.overlay = overlay

(jQuery window).bind 'resize', -> totalRecalc()
