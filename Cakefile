path = require 'path'
{ run, compileScript, exec } = require 'muffin'

task 'build', 'compile coffeescript → javascript', (options) ->
    run
        options:options
        files:[
            "./src/**/*.coffee"
        ]
        map:
            'src/test/(.+).coffee': (m) ->
                compileScript m[0], path.join("test" ,"#{m[1]}.js"), options
            'src/(.+).coffee': (m) ->
                compileScript m[0], path.join("lib" ,"#{m[1]}.js"), options
