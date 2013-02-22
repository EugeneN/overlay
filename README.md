# Overlay
Overlay manager without tying to the content. Is a overlay manager, which means that it controls the sequence of the display of the overlays. He controls the display order and execution of events for each of the created overlay. Also supports asynchronous mapping content.

# History
It was necessary to create a overlay manager without tying to the content and being able to manage a group of the overlays. It was not possible to use the YUI, only jQuery.

# Event API
olayRemove
    Remove overlay from the DOM and from the memory of the overlay manager.
Example:
```
    overlayJNode.trigger('olayRemove');
```
Where:
overlayJNode - it is jQuery element of the overlay node.

olayRecalcTop

olayLoaded

olayClosed

# Browser Support
...
