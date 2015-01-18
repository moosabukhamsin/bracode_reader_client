require 'sequel'
require "net/http"
require "uri"
require 'json'
require 'thor'

class Barcode
  attr_accessor :db, :config_vars

  def initialize
     #load config from config file or set default value
     self.config_vars={
      'database_path' => 'mysql2://root:123456@localhost/barcode',
      'pipe_path' => 'my_pipe',
      'server_path' => 'http://localhost:3000/'
     }
     #

    f=File.open('barcode.config',"r")
    a=f.read
    if a.chomp.size > 0
      self.config_vars=JSON.parse(a)
    end
  end

  def db
    if @db.nil?
      @db=Sequel.connect(self.config_vars['database_path'])
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
    uri = URI.parse("#{self.config_vars['server_path']}/items.json")
    response = Net::HTTP.get_response(uri)
    my_hash = JSON.parse(response.body)
    items = self.db()[:items]
    items.select_all.delete
    my_hash.each do |mh|
    items.insert(name: mh["name"], number: mh["number"])
    end
  end


  def save_config(database_path, pip_path, server)
    # save this in config file
    self.config_vars['database_path']=database_path
    self.config_vars['pipe_path']=pip_path
    self.config_vars['server_path']=server

    f=File.open('barcode.config',"w")
    f.puts(JSON.dump(self.config_vars))
  end

  def getname(number)
    item=self.db[:items].where(number: number).first
    if item
      return item[:name]
    else
      return "Not found"
    end
  end

  
  def speak(str)
    system("echo #{str} | espeak -s 100")
  end

  def speakg(num)
    name=self.getname(num)
    system("echo #{name} | espeak -s 100")
  end


end
