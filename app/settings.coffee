sysPath = ->
  require('path').join(DX16.dirs.module, 'settings.cson')


userPath = ->
  require('path').join(DX16.dirs.user, 'settings.cson')


module.exports =

  load: (cb) ->
    { fs, path } = DX16
    cson = require 'cson-parser'

    DX16.settings.system = {}

    console.log "Loading settings..."
    console.log "  system #{sysPath()}..."
    fs.readFile sysPath(), (err, data) ->
      if !err?
        if data.length
          DX16.settings.system = cson.parse(data)
        else
          DX16.settings.system = {}

        console.log "  user #{userPath()}..."
        fs.readFile userPath(), (err, data) ->
          if !err?
            if data.length
              DX16.settings.user = cson.parse(data)
            else
              DX16.settings.user = {}
          cb(err) if cb?
      else
        throw err
        cb(err) if cb?


  save: (cb) ->
    cson = require 'cson-parser'
    console.log "Saving settings..."
    console.log "  user"
    if DX16.settings? and DX16.settings.user?
      require('fs').writeFile userPath(), cson.stringify(DX16.settings.user, null, 2), (err) ->
        cb(err) if cb?


  saveSync: ->
    cson = require 'cson-parser'
    console.log "Saving settings (sync)..."
    console.log "  user"
    if DX16.settings? and DX16.settings.user?
      require('fs').writeFileSync userPath(), cson.stringify(DX16.settings.user, null, 2)


  set: (key, value, autosave=false) ->
    _.setValueForKeyPath DX16.settings.user, key, value
    if autosave
      @save()


  get: (key, defaultValue) ->
    _.valueForKeyPath _.extend({}, DX16.settings.system, DX16.settings.user), key

