#!/usr/bin/env ruby
$LOAD_PATH.unshift(File.dirname(__FILE__) + '/lib') unless $LOAD_PATH.include?(File.dirname(__FILE__) + '/lib')

# Powerdns-gdocs
# Script for synchronization between gdocs and PowerDNS records in MySQL db.
# You can use google spreadsheet as UI for your DNS records in PowerDNS then.
#
# file:             pdns_gdocs.rb
# author:           Daniel Mrózek
# project homepage: https://github.com/mrazicz/powerdns-gdocs
# author homepage:  https://github.com/mrazicz

require "rubygems"
require "bundler/setup"

require "yaml"
require "gdocs_controller"
require "pdns_controller"
require "resolv"
require "timeout"

config = YAML.load_file(File.expand_path(File.dirname(__FILE__)) + '/config.yml')

gdoc = GdocsController.new(config["gmail"]["user"], config["gmail"]["pass"], config["gmail"]["key"])
gdoc.connect
records = gdoc.get_records

db = PdnsController.new(config["db"], config["pdns"])

resolver = Resolv::DNS.new(:nameserver => "127.0.0.1")

records.each do |key, record|
  unless ARGV[0] == "--checkreg" || ARGV[0] == "-c"
    db.del(record)  if ARGV[0] == "--force" || ARGV[0] == "-f"

    r = db.add(record)
    
    gdoc.set_registro(key) unless r.nil?
    gdoc.set_ip(key, record[1]) unless r.nil? 

    unless r.nil? || record[2] == "failed"
      succ = true
      3.times do
        begin
          Timeout::timeout(3) do
            resolver.getaddress(record[0])
            succ = true
          end
        rescue
          succ = false
        end
      end

      if succ
        gdoc.set_status(key)
      else
        gdoc.set_status(key, "failed")
      end
    end
  end
  
  if ARGV[0] == "--checkreg" || ARGV[0] == "-c" || ARGV[0] == "--force" || ARGV[0] == "-f"
    r = db.check_reg(record)
    if r
      gdoc.set_registro(key, "yes")
    else
      gdoc.set_registro(key, "NO")
    end
  end

end

resolver.close

gdoc.save
