{spawn} = require 'child_process'


build = (callback) ->
    coffee = spawn 'coffee', ['-c', '-o', 'lib', 'src']

    coffee.stderr.on 'data', (data) -> process.stderr.write data.toString()

    coffee.on 'exit', (code) ->
        console.log "Build is done"

        callback?() if code is 0


task 'build', 'Build Overlay lib', -> build()
