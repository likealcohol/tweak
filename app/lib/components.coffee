###
  This class provides a collection of components. Upon initialisation components
  are dynamically built, from its configuration. The configuration for this
  component is an Array of component names (Strings). The component names are
  then used to create a component. Components nested within those components are
  then initialised creating a powerful scope of nest components that are completely
  unique to themselves.

  Examples are in JS, unless where CoffeeScript syntax may be unusual. Examples
  are not exact, and will not directly represent valid code; the aim of an example
  is to show how to roughly use a method.
###
class tweak.Components extends tweak.Collection
   # @property [String] The type of Store, i.e. 'collection', 'components' or 'model'.
  _type: "components"
  # @property [Method] see tweak.Common.relToAbs
  relToAbs: tweak.Common.relToAbs
  # @property [Method] see tweak.Common.splitMultiName
  splitMultiName: tweak.Common.splitMultiName

  ###
    The constructor initialises the controllers unique ID, relating Component, its root and its initial configuration.
  ###
  constructor: (@component, @config = []) ->
    @root = @component.root
    @uid = "cp_#{tweak.uids.cp++}"

  ###
   Construct the Collection with given options from the Components configuration.
  ###
  init: ->
    @data = []
    data = []
    _name = @component.name or @config.name
    for item in @config
      obj = {}
      if item instanceof Array
        names = @splitMultiName _name, item[0]
        path = @relToAbs _name, item[1]
        for name in names
          @data.push new tweak.Component @, {name, extends:path}
      else if typeof item is "string"
        data = @splitMultiName _name, item
        for name in data
          @data.push new tweak.Component @, {name}
      else
        obj = item
        name = obj.name
        data = @splitMultiName _name, name
        obj.extends = @relToAbs _name, obj.extends
        for prop in data
          obj.name = prop
          @data.push new tweak.Component @, obj
      @data[@length++].init()
    return

  ###
    @private
    Reusable method to render and re-render.
    @param [String] type The type of rendering to do either "render" or "rerender".
  ###
  __componentRender: (type) ->
    if @length is 0
      @triggerEvent "ready"
    else
      @total = 0
      for item in @data
        item.controller.addEvent "ready", ->
          if ++@total is @length then @triggerEvent "ready"
        , @, 1
        item[type]()
    return

  ###
    Renders all of its Components.
    @event ready Triggers ready event when itself and its sub-Components are ready/rendered.
  ###
  render: ->
    @__componentRender "render"
    return

  ###
    Re-render all of its Components.
    @event ready Triggers ready event when itself and its sub-Components are ready/re-rendered.
  ###
  rerender: ->
    @__componentRender "rerender"
    return

  ###
    Find Component with matching data in model.
    @param [String] property The property to find matching value against.
    @param [*] value Data to compare to.
    @return [Array] An array of matching Components.
  ###
  whereData: (property, value) ->
    result = []
    componentData = @data
    for collectionKey, data of componentData
      modelData = data.model.data or model.data
      for key, prop of modelData when key is property and prop is value
        result.push data
    result

  ###
    Reset this Collection of components. Also destroys it's components (views removed from DOM).
    @event changed Triggers a generic event that the store has been updated.
  ###
  reset: ->
    for item in @data
      item.destroy()
    super()
    return