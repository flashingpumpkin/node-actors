(function() {
  var Actor, Connection, Message, amqp, bison, events, uuid;
  var __bind = function(func, context) {
    return function(){ return func.apply(context, arguments); };
  }, __extends = function(child, parent) {
    var ctor = function(){};
    ctor.prototype = parent.prototype;
    child.prototype = new ctor();
    child.prototype.constructor = child;
    if (typeof parent.extended === "function") parent.extended(child);
    child.__super__ = parent.prototype;
  };
  amqp = require('amqp');
  uuid = require('uuid');
  events = require('events');
  bison = require('../lib/bison');
  exports.VERSION = '0.0.1';
  Connection = function(_arg) {
    this.connection = _arg;
    this.connection.on('ready', __bind(function() {
      this.messages = this.connection.exchange('actor-messages');
      return this.messages.on('open', __bind(function() {
        this.replies = this.connection.exchange('actor-replies');
        return this.replies.on('open', __bind(function() {
          return this.emit('ready');
        }, this));
      }, this));
    }, this));
    return this;
  };
  __extends(Connection, events.EventEmitter);
  Connection.prototype.createActor = function(id) {
    return new Actor(id.toString(), this.connection, this.messages, this.replies);
  };
  Message = function(_arg, reply_func) {
    this.message = _arg;
    if (reply_func) {
      this.reply = reply_func;
    }
    return this;
  };
  Actor = function(_arg, _arg2, _arg3, _arg4) {
    this.replies = _arg4;
    this.messages = _arg3;
    this.connection = _arg2;
    this.id = _arg;
    this.queue = this.connection.queue(this.id, {
      ack: true
    }).on('open', __bind(function() {
      this.queue.bind('actor-messages', 'actor.' + this.id);
      this.queue.subscribe(__bind(function(message) {
        return this.receive(message);
      }, this));
      return this.emit('ready');
    }, this));
    return this;
  };
  __extends(Actor, events.EventEmitter);
  Actor.prototype.receive = function(message) {
    var data, replyFunc;
    data = bison.decode(message.data.toString());
    if (data.from) {
      replyFunc = __bind(function(reply) {
        return this.reply(data.from, reply);
      }, this);
    } else {
      replyFunc = null;
    }
    return this.emit('message', new Message(data.message, replyFunc));
  };
  Actor.prototype.receiveReply = function(message, callback) {
    return callback(bison.decode(message.data.toString()).message);
  };
  Actor.prototype.reply = function(id, message) {
    return this.replies.publish('reply.' + id.toString(), bison.encode({
      message: message
    }));
  };
  Actor.prototype.send = function(id, message, callback) {
    var replyQueue, replyQueueId;
    if (callback) {
      replyQueueId = uuid.generate();
      return (replyQueue = this.connection.queue(replyQueueId, {
        ack: true
      }).on('open', __bind(function() {
        replyQueue.bind('actor-replies', 'reply.' + replyQueueId);
        replyQueue.subscribe(__bind(function(message) {
          this.receiveReply(message, callback);
          return replyQueue.destroy();
        }, this));
        return this.messages.publish('actor.' + id.toString(), bison.encode({
          from: replyQueueId,
          message: message
        }));
      }, this)));
    } else {
      return this.messages.publish('actor.' + id.toString(), bison.encode({
        message: message
      }));
    }
  };
  exports.createConnection = function(options) {
    var actor, conn;
    conn = amqp.createConnection(options);
    actor = new Connection(conn);
    return actor;
  };
}).call(this);
