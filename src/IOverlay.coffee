{data_to_opts} = require 'libprotein'


EVENT =
    HIDE:      'olayHide'
    SHOW:      'olayShow'

    SHOWN:     'olayShown'
    CLOSED:    'olayClosed'

# Objects of the fully finished overlays.
OVERLAYS = {}
# Global state :( performance optimization.
_COUNT = 0


getOpts = (node) -> data_to_opts 'overlay', node

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

recalc = (olayId) ->
    vpHeight = window.innerHeight
    vpWidth = window.innerWidth

    # Recalculate wrapper size.
    wp = getWrapper olayId
    wp.css('height', vpHeight).css('width', vpWidth)

    # Recalculate mask size.
    mask = getMask olayId
    mask.css('height', vpHeight).css('width', wp[0].scrollWidth)

    # Recalculate top params.
    olay = jQuery "##{olayId}"
    left = (vpWidth - olay.outerWidth()) / 2
    olay.css('top', calcTop olayId).css('left', left)

totalRecalc = -> recalc i for i of OVERLAYS

hideOlay = (id) ->
    (jQuery document.body).css 'overflow', 'auto' if _COUNT is 1
    (getWrapper id).hide()
    (jQuery "##{id}").trigger EVENT.CLOSED, id
    _COUNT -= 1

showOlay = (id) ->
    olay = (jQuery "##{id}").show()
    (jQuery document.body).css 'overflow', 'hidden'
    (getWrapper id).show()

    recalc id
    _COUNT += 1
    olay.trigger EVENT.SHOWN, id


impl = (olayId) ->

    _makeWrapper = ->
        olay = (jQuery "##{olayId}").remove().clone()
        wrapper = (jQuery "<div>").append olay
        (jQuery document.body).append wrapper

        wrapperStyle =
            'position': 'fixed'
            'top': 0
            'left': 0
            'overflow-y': 'auto'
            'overflow-x': 'hidden'
            'z-index': getMaxZIndex()

        wrapper.css prop, val for prop, val of wrapperStyle
        storeWrapper olayId, wrapper

    mask = jQuery "<div style='position: fixed; left: 0; top: 0;'></div>"
    MaskColor = (val) -> mask.css 'background-color', val

    MaskOpacity = (val) -> mask.css 'opacity', val or 0.8

    CloseOnMask = (bool) ->
        opacity = parseFloat (mask.css 'opacity'), 10

        _mouseenter = -> mask.fadeTo(100, opacity + 0.1).css('cursor', 'pointer')

        _mouseout = ->
            mask.fadeTo(160, opacity).css('cursor', 'default') if mask.is ":visible"

        mask.click -> hideOlay olayId
        mask.hover _mouseenter, _mouseout

    _afterLoad = ->
        olay = jQuery "##{olayId}"

        mask.css 'z-index', getMaxZIndex()
        (getWrapper olayId).append storeMask olayId, mask

        olay.css prop, val for prop, val of {'position': 'absolute'}
        zIndex = storeZIndex olayId, getMaxZIndex() + 1

        olay.css('z-index', zIndex)
            .on(EVENT.HIDE, -> hideOlay olayId)
            .on(EVENT.SHOW, -> showOlay olayId)


    # Order is important.
    {_makeWrapper, MaskColor, MaskOpacity, CloseOnMask, _afterLoad}


_handleKeyUp = (ev) ->
    return null unless ev.which is 27 # key escape

    # Hide top visible overlay.
    ids = (i for i, o of OVERLAYS).reverse()
    ids.map (id) -> hideOlay id if (jQuery "##{id}").is ':visible'

(jQuery document.body).on 'keyup', _handleKeyUp
(jQuery window).on 'resize', -> totalRecalc()


module.exports =
    protocols:
        definitions:
            IOverlay: [
                ['*cons*',  [], {concerns: {before: [getOpts]}}]

                ['olayShown', ['f']]

                ['overlay', ['content']]
                ['hide',    []]
                ['show',    []]
            ]

        implementations:
            IOverlay: (node, opts) ->
                jnode = jQuery node


                olayShown: (f) -> jnode.bind EVENT.SHOWN, f


                overlay: (content, cont) ->
                    olayId = jnode.attr 'id'
                    return showOlay olayId if olayStored olayId

                    jnode.append content
                    storeOlayId olayId, opts

                    # Execute methods with the received options.
                    (fn opts[name]) for name, fn of (impl olayId, content)
                    showOlay olayId

                hide: -> jnode.trigger EVENT.HIDE

                show: -> jnode.trigger EVENT.SHOW
