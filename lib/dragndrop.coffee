class DragNDropManager

  debugEnabled : false

  dragDisabled : false

  constructor: ->
    if @debugEnabled
      @debug = $('<div id="debug"></div>')
      @debug.appendTo($('body'))

    @dropTargets = []
    @draggables = []

    $(document).mousedown(@onMouseDown)
    $(document).resize(=>
      # TODO
    )

  addDropTarget: (el, handler) ->
    $el = $(el)
    pos = $el.offset()
    @dropTargets.push({
      top:pos.top,
      left:pos.left,
      bottom:pos.top + $el.width(),
      right: pos.left + $el.height(),
      width:$el.width(),
      height:$el.height(),
      el:el,
      handler:handler
    })

  addDraggable: (el) ->
    @draggables.push(el)

  onMouseDown: (e) =>

    return if @disabled

    return unless e.target? and @arrayContains(@draggables, e.target)

    $dragging = $(e.target)
    position = $dragging.css('position')
    $dragging.css('position', 'relative')

    return unless e.which is 1

    clickX = e.pageX
    clickY = e.pageY

    offsetX = @toNumber($dragging.css('left'))
    offsetY = @toNumber($dragging.css('top'))


    counter = 0

    $(document).mousemove((e)=>

        newX = offsetX + e.pageX - clickX
        newY = offsetY + e.pageY - clickY

        $dragging.css('left', "#{newX}px")
        $dragging.css('top', "#{newY}px")

        if @debugEnabled
          @debug.html("#{++counter} left: #{newX} top: #{newY} offset: #{offsetX} page: #{e.pageX} start: #{clickX}")
    )

    $(document).mouseup((e) =>

      target = @getDropTarget(e.pageX, e.pageY)

      target.handler($dragging) if target?

      $(document).unbind('mousemove')
      $(document).unbind('mouseup')

      $dragging.css('left', "0px")
      $dragging.css('top', "0px")
      $dragging.css('position', position)

    )

    return false

  # probably benefit from a quad tree for a large number of targets..
  getDropTarget: (x, y) ->
    for target in @dropTargets
      if x > target.left and y > target.top and x < target.right and y < target.bottom
        return target


  toNumber: (str) ->
    return unless str?
    str = str.toString()
    str = str.replace /px/, ""
    ret = +str
    ret = 0 if ret == null or isNaN(ret)
    ret

  arrayContains: (array, value) ->
    for val in array
      return true if val is value
    return false

