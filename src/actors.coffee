# **Actors** is a little library to provide inter- and inprocess
# message passing between objets.
# 
# **Actors** makes usage of [RabbitMQ](http://www.rabbitmq.com), [node-amqp](https://github.com/ry/node-amqp), [BiSON.js](https://github.com/BonsaiDen/BiSON.js) 
# and [uuidjs](http://bitbucket.org/nikhilm/uuidjs)
#
# To install **Actors**, run `npm` from command line:
#
#       npm install actors
#
#

amqp = require 'amqp'
uuid = require 'uuid'
events = require 'events'
bison = require '../lib/bison'


#### Actors library

exports.VERSION = '0.0.1'

class Connection extends events.EventEmitter
    # The connection passed in is a amqp.Connection instance connected to 
    # a RabbitMQ server.
    #
    # Once the handshake is done and the connection is ready, two simple
    # exchanges are set up to pass messages back and forth.
    constructor: (@connection)->
        @connection.on 'ready', =>
            @messages = @connection.exchange 'actor-messages'
            @messages.on 'open', =>
                @replies  = @connection.exchange 'actor-replies'
                @replies.on 'open', =>
                    @emit 'ready'

    # Method to create new actors using the current AMQP connection.
    createActor: (id)->
        return new Actor id.toString(), @connection, @messages, @replies

# A message is an object with an attribute ``message`` and an optional 
# method ``reply``, that gets set if the sender expects a reply to the
# message to come back.
class Message
    constructor: (@message, reply_func)->
        if reply_func
            @reply = reply_func

# Actors are the objects everything interesting happens on. Once an actor
# is created, we can simply pass messages back and forth between any
# other actors, independent of their location.
#
# Each actor has its own queue to listen for new messages on and binds
# to the `actor-messages` exchange.
class Actor extends events.EventEmitter
    constructor: (@id, @connection, @messages, @replies)->
        @queue = @connection.queue(@id, ack: true)
            .on 'open', =>
                @queue.bind 'actor-messages', 'actor.'+@id
                @queue.subscribe (message) =>
                    @receive message
                @emit 'ready'

    # Once a message is received, it's restored and wrapped into 
    # a `Message` object. If there is information about the sender included
    # in the message, the `Message` object also receives a function to 
    # send a reply back to the original sender.
    receive: (message)->
        data = bison.decode(message.data.toString())

        if data.from
            replyFunc= (reply) =>
                @reply data.from, reply
        else
            replyFunc = null

        @emit 'message', new Message data.message, replyFunc

    # Call the provided callback with the reply.
    receiveReply: (message, callback) ->
        callback bison.decode(message.data.toString()).message

    reply: (id, message) ->
        @replies.publish 'reply.'+id.toString(), bison.encode({ message: message})

    # When sending messages to another actor, two arguments need to be provided. First
    # of all, the actor's `id`. This maps to the actor's queue. The second argument is 
    # a message. This can be anything that [BiSON.js](https://github.com/BonsaiDen/BiSON.js/)
    # understands.
    #
    #       actor.send('cake-shop', { cakes_inventory: 10})

    send: (id, message, callback)->
        # If there is an optional callback provided, the actor sending the message 
        # creates a temporary queue on which the actor's going to expect a reply
        # from the receiving actor.
        #
        # Once all is ready, send!
        if callback
            replyQueueId = uuid.generate()
            replyQueue = @connection.queue(replyQueueId, ack: true)
                .on 'open', =>
                    replyQueue.bind 'actor-replies', 'reply.'+replyQueueId
                    replyQueue.subscribe (message) =>
                        @receiveReply message, callback
                        replyQueue.destroy()
                    @messages.publish('actor.'+id.toString(), bison.encode({ from: replyQueueId, message: message}))
        else
            @messages.publish('actor.'+id.toString(), bison.encode({ message: message}))

# The only export wraps `amqp.createConnection` and creates a new actor connection that
# receives the AMQP connection to work with. Then the actor object is returned.
exports.createConnection = (options)->
    conn = amqp.createConnection options
    actor = new Connection conn
    return actor



