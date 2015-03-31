###
  tweak.view.html.js 1.1.0

  (c) 2014 Blake Newman.
  TweakJS may be freely distributed under the MIT license.
  For all details and documentation:
  http://tweakjs.com
###

tweak.Viewable = {
  width : window.innerWidth or (document.documentElement or document.documentElement.getElementsByTagName('body')[0]).clientWidth
  height : window.innerHeight or (document.documentElement or document.documentElement.getElementsByTagName('body')[0]).clientHeight
}

###
  This class extends the View class, extending its rendering functionality for HTML.
  The ViewHTML class does not provide functionality to manipulate this Views
  presentation layer. To extend the HTMLView to provide extra functionality to
  manipulate this View's rendered interface (DOM) please include the optional
  tweak.ViewHTMLAdvanced class.

  Examples are in JS, unless where CoffeeScript syntax may be unusual. Examples
  are not exact, and will not directly represent valid code; the aim of an example
  is to show how to roughly use a method.
###
class tweak.ViewHTML extends tweak.View
  # @property [Method] see tweak.Common.require
  require: tweak.Common.require
  # @property [Method] see tweak.Common.splitMultiName
  splitMultiName: tweak.Common.splitMultiName
  # @property [Method] see tweak.Common.relToAbs
  relToAbs: tweak.Common.relToAbs
  # @property [Method] see tweak.Common.findModule
  findModule: tweak.Common.findModule

  ###
    Default initialiser function - called when the View has rendered
  ###
  init: ->

  ###
    Renders the View, using a html template engine. The View is loaded asynchronously, this prevents the DOM from
    from congesting during rendering. The View won't be rendered until its parent View is rendered and any other
    components Views that are waiting to be rendered; this makes sure that components are rendered into in there
    correct positions.
    
    @param [Boolean] silent (Optional, default = false) If true events are not triggered upon any changes.
    @event rendered The event is called when the View has been rendered.
  ###
  render: (silent) ->
    if @isRendered() and not silent
      @triggerEvent "rendered"
      return
      
    if not @model? then throw new Error "No model attached to View"
    config = @config
    config.attach ?= {}

    @name = @component.name or @config.name or @uid
    
    # Makes sure that there is an id for this component set, either by the config or by its name
    className = @model.data.className = @config.className or @name.replace /[\/\\]/g, "-"

    # Build the template with the date from the model
    template = if config.template then @require @name, config.template else @findModule @component.paths, './template'
    template = template @model.data
    
    # Create HTML element add add to DOM
    rendered = (template) =>
      # Attach template to the DOM and set @el
      attachTo = @config.attach?.to or @config.attach?.name or @name
      parent = @component.parent?.view?.el
      html = document.documentElement
      attachment = if attachTo.tagName then attachTo
      else @getAttachmentNode(parent) or @getAttachmentNode(html) or parent or html
      
      @el = @attach attachment, template, config.attach.method
        
      # Attempt to add class and uid
      strip = /^\s+|\s\s+|\s+$/
      @el.className = "#{@el.className} #{className}".replace strip, ''
      @el.id = "#{@el.id} #{@uid}".replace strip, ''

      if not silent then @triggerEvent "rendered"
      @init()

    @createAsync template, rendered
    return

  ###
    Get the children nodes of an element.
    @param [DOMElement] parent The element to retrieve the children of
    @param [Boolean] recursive (Default: true) Whether to recursively go through its children's children to get a full list
    @return [Array<DOMElement>] Returns an array of children nodes inside an element
  ###
  getChildren: (element, recursive = true) ->
    result = []
    children = (node = {}) ->
      nodes = node.children or []
      for node in nodes
        result.push node
      for node in nodes
        if recursive and node.children then children node
      return
    # Iterate though all children of an element
    children element
    result

  ###
    Clears the View and removed event listeners of DOM elements.
  ###
  clear: (element = @el) ->
    if element?.parentNode
      try
        element.parentNode.removeChild element
        element = null
    return

  ###
    Checks to see if the item is rendered; this is determined if the node has a parentNode.
    @return [Boolean] Returns whether the View has been rendered.
  ###
  isRendered: -> if document.documentElement.contains @el then true else false
  
  ###
    Get the attachment node for this element.
    @param [DOMElement] parent the DOM Element to search in
    @return [DOMElement] Returns the parent DOMElement.
  ###
  getAttachmentNode: (parent) ->
    if not parent then return
    # The result is the parent el, or it will try to find a node to attach to in the DOM
    name = @config.attach?.to or @config.attach?.name or @name
    nodes = @getChildren parent
    nodes.unshift parent
    for prop in nodes
      if child then break
      attachment = prop.getAttribute 'data-attach'
      if attachment? and not attachment.match /\s+/
        for val in @splitMultiName name, attachment
          if name is val
            child = prop
            break
    child

  ###
    Attach a DOMElement to another DOMElement. Attachment can happen by three methods, inserting before, inserting after, inserting at position and replacing.

    @param [DOMElement] parent DOMElement to attach to.
    @param [DOMElement] node DOMElement to attach to parent.
    @param [String, Number] method (Default = append) The method to attach ('prefix'/'before', 'replace', (number) = insert at position) any other method will use the attach method to insert after.
  ###
  attach: (parent, node, method) ->
    switch method
      when 'prefix', 'before'
        parent.insertBefore node, parent.firstChild
        return parent.firstElementChild
      when 'replace'
        for item in parent.children
          try
            parent.removeChild item
          catch e
        parent.appendChild node
        return parent.firstElementChild
      else
        if /^\d+$/.test "#{method}"
          num = Number(method)
          parent.insertBefore node, parent.children[num]
          return parent.children[num]
        else
          parent.appendChild node
          return parent.lastElementChild

  ###
    Create an Element from a template string.
    
    @param [String] template A template String to parse to a DOMElement.
    @return [DOMElement] Parsed DOMElement.
  ###
  create: (template) ->
    temp = document.createElement "div"
    frag = document.createDocumentFragment()
    temp.innerHTML = template
    temp.firstChild

  ###
    Asynchronously create an Element from a template string.
    
    @param [String] template A template String to parse to a DOMElement.
    @return [DOMElement] Parsed DOMElement.
  ###
  createAsync: (template, callback) -> setTimeout => callback @create template, 0
  
tweak.View = tweak.ViewHTML