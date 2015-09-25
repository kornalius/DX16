r = require('remote')
a = r.require('app')
p = r.require('path')
ipc = require('ipc')

userPath = p.join(a.getPath('home'), '.dx16')

if !window._?
  window._ = require('underscore-plus')

  _.extend _,
    uncapitalize: (str) ->
      return str[0].toLowerCase() + str.slice(1)

  _.extend _, require('lodash')

  _.extend(_, require('underscore-contrib'))
  _.extend(_, require('starkjs-underscore'))
  _.number = require('underscore.number')
  _.array = require('underscore.array')

if !window.DX16?
  window.DX16 =
    remote: r
    app: a
    BrowserWindow: r.require('browser-window')
    appWindow: r.getCurrentWindow()
    dirs:
      home: a.getPath('home')
      app: a.getPath('appData')
      user: userPath
      tmp: a.getPath('temp')
      root: a.getPath('exe')
      module: p.dirname(module.filename)
      node_modules: p.join(userPath, 'node_modules')
      user_pkg: p.join(userPath, 'package.json')
    path: p
    fs: r.require 'fs-plus'
    ipc: ipc
    buffer: r.require 'buffer'
    http: r.require 'http'
    url: r.require 'url'
    util: r.require 'util'
    IS_WIN: /^win/.test process.platform
    IS_OSX: process.platform == 'darwin'
    IS_LINUX: process.platform == 'linux'
  _.extend DX16,
    settings: require('./settings.coffee')


# Make sure home DX16 directory exists
if !DX16.fs.existsSync(userPath)
  DX16.fs.mkdirSync(userPath)

console.log "Booting #{a.getName()} v#{a.getVersion()}..."
console.log "io.js: #{process.version}"
console.log "Electron: #{process.versions['electron']}"
console.log ""
console.log "Root path: #{DX16.dirs.root}"
console.log "Module path: #{DX16.dirs.node_modules}"
console.log "Temp path: #{DX16.dirs.tmp}"
console.log "App path: #{DX16.dirs.app}"
console.log "User path: #{DX16.dirs.user}"
console.log "Home path: #{DX16.dirs.home}"

DX16.PIXI = PIXI

Video = require('./video.coffee').Video
video = null

ipc.on 'load', ->

  pegjs = require('pegjs')
  grammar = DX16.fs.readFileSync(p.join(__dirname, 'grammar.pegjs')).toString()
  try
    parser = pegjs.buildParser(grammar, { trace: false })
  catch e
    console.error "line: #{e.location.start.line} col: #{e.location.start.column} --> #{e.toString()}"
  # parser = require('./parser.js')

  DX16.settings.load (err) ->

    video = new Video()

    video.drawRect(0, 0, 200, 240, 0x00FF00)
    r = video.drawRect(10, 10, 100, 100, 0xFF0000, 0.75)
    video.drawLine(20, 20, 200, 200, 2, 0xFFFF00)

    video.print(0, 0, "Welcome to DX16 computer system")
    video.print(0, 1, "Loading OS... Please wait...")

    for i in [3...video.textHeight]
      video.print(0, i, "-123456789-123456789-123456789-123456789-123456789-123456789-123456789-123456-" + i)

    setInterval(->
      r.position.x += [-1, 0, 1][_.random(0, 2)]
      r.position.y += [-1, 0, 1][_.random(0, 2)]
      video.refresh()
    , 100)

    code = """
      2 * (3 + 4)

      def print {}

      { print 'hello'}

      if 10 > (2 * 3)
        print ['hello']
        print 65
      ; else if 10 < 2
      ;   print 'ohoh'
      ; else
      ;   print 'works'

      if 2 < 2 / 3 { print 'hello' }

      a = 10
      def fun a b c {print a, b ,c}
      fun a
    """

    indents = [0]
    indent = 0

    preproc = code.replace(/\t/g, ' ')

    ll = []
    for l in preproc.split('\n')
      rr = l.replace(/^(\s*).*$/, '$1')
      if rr?
        i = rr.length
      else
        i = 0

      nl = l.replace(/^\s*(.*)$/, '$1')

      if i == indent
        ll.push(nl)
      else if i > indent
        last = ll.pop()
        ll.push("#{last} {")
        ll.push(nl)
        indents.push(indent)
        indent = i
      else if i < indent
        ll.push("}")
        ll.push(nl)
        indent = indents.pop()

    preproc = ll.join('\n')
    console.log preproc

    try
      ast = parser.parse(preproc)
    catch e
      if e?.location?
        i = "line: #{e.location.start.line} col: #{e.location.start.column} --> "
      else
        i = ""
      console.error("#{i}#{e.toString()}")
      ast = ""
    console.log ast

    compiler = require('./compiler.coffee')
    console.log compiler.compile(ast)


ipc.on 'unload', ->
  DX16.settings.saveSync()

  video.destroy()
  video = null
