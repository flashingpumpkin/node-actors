sys = require 'sys'
actors = require '../lib/actors'
assert = require 'assert'

server = actors.createConnection({ host: 'localhost'})

server.on 'ready', ->
    shop = server.createActor 'shop'
    customer = server.createActor 'customer'

    shop.on 'message', (message) ->
        console.log JSON.stringify message.message
        switch JSON.stringify message.message
            when '"cakes"'
                message.reply 10
            when '"order"'
                message.reply 1
            when '[1,2,3]'
                message.reply [4,5,6]

    shop.on 'ready', ->
        customer.send 'shop', 'cakes', (reply)->
            assert.equal reply, 10, 'Got '+reply+' cakes, expected 10'

            customer.send 'shop', 'order', (reply)->
                assert.equal reply, 1, 'Got '+reply+' cakes, expected 1'

                customer.send 'shop', [1,2,3], (reply)->
                    assert.equal JSON.stringify(reply), '[4,5,6]', 'Got '+JSON.stringify(reply)+', expected [4,5,6]'

                    console.log 'Tests passed'
                    process.exit 0


