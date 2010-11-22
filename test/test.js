(function() {
  var actors, assert, server, sys;
  sys = require('sys');
  actors = require('../lib/actors');
  assert = require('assert');
  server = actors.createConnection({
    host: 'localhost'
  });
  server.on('ready', function() {
    var customer, shop;
    shop = server.createActor('shop');
    customer = server.createActor('customer');
    shop.on('message', function(message) {
      console.log(JSON.stringify(message.message));
      switch (JSON.stringify(message.message)) {
        case '"cakes"':
          return message.reply(10);
        case '"order"':
          return message.reply(1);
        case '[1,2,3]':
          return message.reply([4, 5, 6]);
      }
    });
    return shop.on('ready', function() {
      return customer.send('shop', 'cakes', function(reply) {
        assert.equal(reply, 10, 'Got ' + reply + ' cakes, expected 10');
        return customer.send('shop', 'order', function(reply) {
          assert.equal(reply, 1, 'Got ' + reply + ' cakes, expected 1');
          return customer.send('shop', [1, 2, 3], function(reply) {
            assert.equal(JSON.stringify(reply), '[4,5,6]', 'Got ' + JSON.stringify(reply) + ', expected [4,5,6]');
            console.log('Tests passed');
            return process.exit(0);
          });
        });
      });
    });
  });
}).call(this);
