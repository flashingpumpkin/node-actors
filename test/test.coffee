sys = require 'sys'
actors = require '../lib/actors'
assert = require 'assert'

server = actors.createConnection({ host: 'localhost'})

server.on 'ready', ->
    shop = server.createActor 'shop'
    customer = server.createActor 'customer'

    shop.on 'message', (message) ->
        switch message.message
            when 'cakes'
                message.reply 10
            when 'order'
                message.reply 1

    shop.on 'ready', ->
        customer.send 'shop', 'cakes', (reply)->
            assert.equal reply, 10, 'Got '+reply+' cakes, expected 10'

            customer.send 'shop', 'order', (reply)->
                assert.equal reply, 1, 'Got '+reply+' cakes, expected 1'
                sys.puts 'Tests passed'
                process.exit 0
