{ PIXI } = DX16

Stats = require('./stats.js')

PIXI.Point.prototype.distance = (target) ->
  Math.sqrt((@x - target.x) * (@x - target.x) + (@y - target.y) * (@y - target.y))

PIXI.Point.prototype.toString = ->
  "(#{@x}, #{@y})"

PIXI.Rectangle.prototype.toString = ->
  "(#{@x}, #{@y}, #{@x + @width}, #{@y + @height})(#{@width}, #{@height})"


module.exports.Video = class Video

  constructor: (@width = 320, @height = 240, @char_width = 4, @char_height = 6, @resolution = 4) ->

    DX16.appWindow.setContentSize(@width * @resolution, @height * @resolution)
    DX16.appWindow.center()

    @_lastMouse = new PIXI.Point()

    @textWidth = Math.trunc(@width / @char_width)
    @textHeight = Math.trunc(@height / @char_height)

    @renderer = new PIXI.WebGLRenderer(@width, @height, resolution: @resolution)
    document.body.appendChild(@renderer.view)

    @stage = new PIXI.Container()
    # @stage.interactive = true

    @stats = new Stats()
    document.body.appendChild(@stats.domElement)
    @stats.domElement.style.position = "absolute"
    @stats.domElement.style.bottom = "0px"
    @stats.domElement.style.left = "0px"

    @text_palette =
      fg        : 0xd0d0d0
      bg        : 0x151515
      black     : 0x151515
      red       : 0xac4142
      green     : 0x90a959
      yellow    : 0xf4bf75
      blue      : 0x6a9fb5
      magenta   : 0xaa759f
      cyan      : 0x75b5aa
      white     : 0xd0d0d0
      brblack   : 0x505050
      brred     : 0xac4142
      brgreen   : 0x90a959
      bryellow  : 0xf4bf75
      brblue    : 0x6a9fb5
      brmagenta : 0xaa759f
      brcyan    : 0x75b5aa
      brwhite   : 0xf5f5f5

    @blocks = []
    @lines = []

    @clear()

    that = @

    setTimeout(->
      for line in that.lines
        line.dirty = true
      that.forceUpdate = true
    , 250)

    update = false

    PIXI.ticker.shared.add (time) ->
      that.stats.begin()

      for y in [0...that.textHeight]
        if that.lines[y].dirty
          line = that.lines[y]
          px = 0
          l = ''
          line.dirty = false
          update = true

          for block in line.blocks
            that.stage.removeChild(block)
            _.remove(that.blocks, block)
          line.blocks = []

          c = line.chars[0]
          fg = c.fg
          bg = c.bg

          for x in [0...that.textWidth]
            c = line.chars[x]
            if c.fg != fg or c.bg != bg
              that._drawTextBlock(line, px, y, fg, bg, l)
              fg = c.fg
              bg = c.bg
              l = ''
              px = x
            l += c.ch

          if l != ''
            that._drawTextBlock(line, px, y, fg, bg, l)

      if update or that.forceUpdate
        update = false
        that.forceUpdate = false
        that.renderer.render(that.stage)

      that.stats.end()


  refresh: ->
    @forceUpdate = true


  clear: ->
    for block in @blocks
      @stage.removeChild(block)
    @blocks = []

    @lines = []
    for y in [0..@textHeight]
      line =
        blocks: []
        chars: []
        dirty: false
      for x in [0..@textWidth]
        line.chars.push(ch: ' ', fg: @text_palette.fg, bg: @text_palette.bg)
      @lines.push(line)


  put: (x, y, ch, fg, bg) ->
    line = @lines[y]
    line.chars[x] =
      ch: ch
      fg: fg or @text_palette.fg
      bg: bg or @text_palette.bg
    line.dirty = true


  print: (x, y, text, fg, bg) ->
    ls = text.split('\n')
    for l in ls
      line = @lines[y++]
      for ch in l
        line.chars[x++] =
          ch: ch
          fg: fg or @text_palette.fg
          bg: bg or @text_palette.bg
      line.dirty = true


  _drawTextBlock: (line, x, y, fg, bg, text) ->
    if bg != @text_palette.bg
      b = new PIXI.Graphics()
      b.beginFill(bg)
      b.drawRect(0, 0, text.length * @char_width, @char_height)
      b.endFill()
      b.position.x = x * @char_width
      b.position.y = y * @char_height
      @stage.addChild(b)
      line.blocks.push(b)
      @blocks.push(b)

    t = new PIXI.Text(text, font: "4px PixelFont", fill: fg)
    t.resolution = @resolution
    t.position.x = x * @char_width
    t.position.y = y * @char_height
    @stage.addChild(t)
    line.blocks.push(t)
    @blocks.push(t)


  drawRect: (x, y, w, h, color, alpha = 1) ->
    b = new PIXI.Graphics()
    b.beginFill(color, alpha)
    b.drawRect(0, 0, w, h)
    b.endFill()
    b.position.x = x
    b.position.y = y
    @stage.addChild(b)
    @blocks.push(b)
    return b


  drawLine: (x, y, x2, y2, w, color, alpha = 1) ->
    b = new PIXI.Graphics()
    b.lineStyle(w, color, alpha)
    b.moveTo(0, 0)
    b.lineTo(x2, y2)
    b.position.x = x
    b.position.y = y
    @stage.addChild(b)
    @blocks.push(b)
    return b


  destroy: ->
    @stage.destroy()
    @stage = null

    @renderer.destroy()
    @renderer = null

