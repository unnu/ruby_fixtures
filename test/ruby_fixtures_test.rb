require File.dirname(__FILE__) + '/test_helper.rb' 
load_schema

class Document < ActiveRecord::Base; end

require 'factory_girl'

Factory.define :document do |f|
  f.name 'my document'
  f.content 'foo bar'
end

class RubyFixturesTest < ActiveSupport::TestCase

  test "add should create fixtures from factory" do
    ruby_fixtures = RubyFixtures.new
    
    ruby_fixtures.instance_eval do
      add :document, :one
    end
    
    assert ruby_fixtures.fixtures.has_key?(:documents)
    assert ruby_fixtures.fixtures[:documents].has_key?(:one)
  end
end
