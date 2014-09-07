require 'rubygems'
require 'bundler/setup'

Bundler.setup

require 'sqlite3'
require 'sequel'
require 'scrypt'
require 'thor'

PATH    = File.expand_path(File.dirname(__FILE__))
DB_PATH = File.join(PATH, 'db')
DB_FILE = 'sqlite:%s' % File.join(DB_PATH, 'pass.db')

DB = Sequel.connect(DB_FILE)

DB.create_table?(:users) do
  primary_key :id
  String :email
  String :secret
  index [:email, :secret], unique: true
end

SCrypt::Engine::calibrate
class CLI < Thor
  desc 'save email password', 'Save an email and password to database'
  def save(email, pass)
    exists = DB[:users].where(email: email).first || false
    if exists
      puts "Email: #{email}, already exists"
      return
    end
    salt = SCrypt::Engine.generate_salt

    p = SCrypt::Engine.hash_secret(pass, salt)
    DB[:users].insert(email:email, secret: p)
  end

  desc 'validate email password', 'Validate an email and password of a user in the database'
  def validate(email, pass)
    exists = DB[:users].where(email: email).first || false
    unless exists
      puts "Could not locate #{email} in the database"
      return
    end

    p = exists[:secret]
    if SCrypt::Password.new(p) == pass
      puts "valid password"
    else
      puts "invalid password"
    end
  end


end

CLI.start(ARGV)

