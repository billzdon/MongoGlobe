require 'test/test_helper'
require 'rubygems'
require 'json'

class JSONTest < Test::Unit::TestCase

  include Mongo
  include BSON

  def assert_json(obj, json)
    assert_equal json, obj.to_json
    assert_equal obj, obj.class.json_create(json)
  end

  def test_json
    id = ObjectID.new
    assert_json id, "{\"$oid\": \"#{id}\"}"
  end

end
