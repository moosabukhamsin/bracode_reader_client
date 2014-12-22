require 'sequel'
require "net/http"
require "uri"
require 'json'

class Barcode
  attr_accessor :db

  def db
    if @db.nil?
      @db=Sequel.connect('mysql://root:123456@localhost/barcode')
    end
    return @db
  end

  def install
    self.db().create_table :items do
      primary_key :id
      String :name
      String :number
    end
  end

  def update
    uri = URI.parse("http://localhost:3000/items.json")
    response = Net::HTTP.get_response(uri)
    my_hash = JSON.parse(response.body)
    items = self.db()[:items]
    my_hash.each do |mh|
      items.insert({name: mh[:name], number: mh[:number]})
    end
  end

  def getname(number)
    return self.db[:items].where(number: number).first[:name]
  end
end