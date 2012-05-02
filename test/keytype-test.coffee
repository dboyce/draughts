require "should"
KeyType = require('../lib/draughts').KeyType

describe "#KeyType", ->
  describe "#constructor", ->
    it "should assign each instance a unique id", ->
      key = new KeyType()
      key2 = new KeyType()
      key.id.should.be.ok
      key2.id.should.be.ok
      key.id.should.not.equal key2.id
    it "should use its ID as its toString value", ->
      key = new KeyType()
      key.toString().should.equal key.id

  describe "should be useable as a key in an object literal", ->
    key = new KeyType()
    key2 = new KeyType()

    map = []
    map[key] = "foo"
    map[key2] = "bar"

    map[key].should.equal "foo"
    map[key2].should.equal "bar"

