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
      switch (message.message) {
        case 'cakes':
          return message.reply(10);
        case 'order':
          return message.reply(1);
      }
    });
    return shop.on('ready', function() {
      return customer.send('shop', 'cakes', function(reply) {
        assert.equal(reply, 10, 'Got ' + reply + ' cakes, expected 10');
        return customer.send('shop', 'order', function(reply) {
          assert.equal(reply, 1, 'Got ' + reply + ' cakes, expected 1');
          sys.puts('Tests passed');
          return process.exit(0);
        });
      });
    });
  });
}).call(this);
