# Actors

Lots has been said about actors and message passing. I've been wondering
how to do that easily and both between processes and objects in the 
same process. 

## Synopsis

    var actors = require('actors');
    var server = actors.createConnection({ host: 'localhost'});
    
    server.on('ready', function(){
        var shop = server.createActor('shop');
        var customer = server.createActor('customer');
        
        shop.on('message', function(message){
            message.reply('Yum Yum')
        })
        
        customer.on('ready', function(){
            customer.send('shop', { question: 'How many cakes are left?' }, function(reply){
                customer.send('shop', { order: reply.cakes })
            });
        });
    });

## Installation

    npm install actors

## Connection

The options on `actors.createConnection` are the same as for [node-amqp](https://github.com/ry/node-amqp)

For more info check out the `docs/` folder.

