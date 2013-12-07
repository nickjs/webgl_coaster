Mincer = require 'mincer'
connect = require 'connect'

env = new Mincer.Environment
env.appendPath 'src'
env.appendPath 'lib'

if process.argv[2] == '-b'
  require('fs').writeFile "#{__dirname}/build/main.js", env.findAsset('main.coffee'), ->
else
  app = connect()
    .use(connect.logger('dev'))
    .use('/assets', Mincer.createServer(env))
    .use(connect.static(__dirname))
    .listen(4000)
