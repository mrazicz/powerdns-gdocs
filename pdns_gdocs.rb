#!/usr/bin/env ruby

# Powerdns-gdocs
# Script for synchronization between gdocs and PowerDNS records in MySQL db.
# You can use google spreadsheet as UI for your DNS records in PowerDNS then.
#
# file:             pdns_gdocs.rb
# author:           Daniel Mrózek
# project homepage: https://github.com/mrazicz/powerdns-gdocs
# author homepage:  https://github.com/mrazicz

require "rubygems"
require "yaml"
require "classes/gdocs_controller"
require "classes/pdns_controller"

config = YAML.load_file('config.yml')

gdoc = GdocsController.new(config["gmail"]["user"], config["gmail"]["pass"], config["gmail"]["key"])
gdoc.connect
records = gdoc.get_records

db = PdnsController.new(config["db"], config["pdns"])

records.each do |key, record|
  db.add(record)
end


