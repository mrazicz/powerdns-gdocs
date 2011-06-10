# This file contains all models for datamapper
class Domain
  include DataMapper::Resource

  property  :id,              Serial
  property  :name,            String, :required => true, :unique => true, :length => 255
  property  :master,          String, :length => 128
  property  :last_check,      Integer
  property  :type,            String, :required => true, :length => 10
  property  :notified_serial, Integer
  property  :account,         String, :length => 40

  has n, :records
  has n, :zones
end

class Zone
  include DataMapper::Resource

  property  :id,              Serial
  property  :domain_id,       Integer,  :required => true
  property  :owner,           Integer,  :required => true
  property  :comment,         Text,     :default => "NULL"

  belongs_to :domain
end

class Record
  include DataMapper::Resource

  property  :id,              Serial
  property  :domain_id,       Integer, :key => true
  property  :name,            String, :length => 255, :key => true
  property  :type,            String, :length => 6
  property  :content,         String, :length => 255
  property  :ttl,             Integer
  property  :prio,            Integer
  property  :change_date,     Integer

  belongs_to :domain
end

class User
  include DataMapper::Resource

  property  :id,              Serial
  property  :username,        String, :length => 16, :required => true
  property  :password,        String, :length => 34, :required => true
  property  :fullname,        String, :length => 255, :required => true
  property  :email,           String, :length => 255, :required => true
  property  :description,     Text, :required => true
  property  :active,          Integer, :required => true
  property  :perm_templ,      Integer, :required => true
end

class PermItem
  include DataMapper::Resource

  property  :id,              Serial
  property  :name,            String, :length => 64, :required => true
  property  :descr,           Text, :required => true
end

class PermTempl
  include DataMapper::Resource

  storage_names[:default] = "perm_templ"

  property  :id,              Serial
  property  :name,            String, :length => 128, :required => true
  property  :descr,           Text, :required => true
end

class PermTemplItem
  include DataMapper::Resource

  property  :id,              Serial
  property  :templ_id,        Integer, :required => true, :key => true
  property  :perm_id,         Integer, :required => true, :key => true
end

class Supermaster
  include DataMapper::Resource

  property  :ip,              String, :length => 25, :required => true, :key => true
  property  :nameserver,      String, :length => 255, :required => true
  property  :account,         String, :length => 40
end

class ZoneTempl
  include DataMapper::Resource

  storage_names[:default] = "zone_templ"

  property  :id,              Serial
  property  :name,            String, :length => 128, :required => true
  property  :descr,           String, :length => 1024, :required => true
  property  :owner,           Integer, :required => true

  has n, :zone_templ_records
end

class ZoneTemplRecord
  include DataMapper::Resource
  
  property  :id,              Serial
  property  :zone_templ_id,   Integer, :required => true, :key => true
  property  :name,            String, :length => 255, :required => true
  property  :type,            String, :length => 6, :required => true
  property  :content,         String, :length => 255, :required => true
  property  :ttl,             Integer, :required => true
  property  :prio,            Integer, :required => true

  belongs_to :zone_templ
end
