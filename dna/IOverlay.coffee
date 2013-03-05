{data_to_opts} = require 'libprotein'

EVENT =
    HIDE: 'olayHide'


# Change options from the data attributes for compatibility with overlay options.
getOpts = (node) ->
    opts = data_to_opts 'overlay', node

    mask: {'color': opts.MaskColor, 'opacity': opts.MaskOpacity}
    top: null
    closeOnEsc: true
    closeOnMask: true
    closeSel: null
    showOnLoad: true
    onLoad: undefined
    onClose: undefined
    triggerSel: null
    removeOnClose: opts.RemoveOnClose


module.exports =
    protocols:
        definitions:
            IOverlay: [
                ['*cons*',  [], {concerns: {before: [getOpts]}}]

                ['olayLoaded', ['f']]

                ['overlay', []]
                ['hide',    []]
            ]

        implementations:
            IOverlay: (node, opts) ->
                jnode = jQuery node


                olayLoaded: (f) -> f()


                overlay: -> jnode.overlay opts

                hide: -> jnode.trigger EVENT.HIDE
