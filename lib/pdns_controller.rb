class PdnsController
  require "data_mapper"
  require "models"
  require "resolv"
  
  # constructor
  def initialize(db, pdns)
    DataMapper.setup(:default, {
      :adapter  => db["adapter"],
      :host     => db["host"],
      :username => db["username"],
      :password => db["password"],
      :database => db["database"]
    })    
    
    DataMapper.finalize
    
    @templates = ZoneTempl.all(:name => pdns["template"]).zone_templ_records
  end
  
  # add new record to db
  def add(record)
    unless exist?(record[0])
      domain = new_domain(record[0])
      zone = new_zone(domain.id)
      for t in @templates
        new_record(t, domain, record)
      end
      return record

     end

    return nil
  end

  # delete record
  def del(record)
    if exist?(record[0])
      domain = Domain.all(:name => record[0])

      domain.records.destroy
      domain.zones.destroy
      domain.destroy
    end
  end

  # registration check
  def check_reg(record)
    if exist?(record[0])
      r = Resolv::DNS.new
      nservers = r.getresources(record[0], Resolv::DNS::Resource::IN::NS)
      template_ns = @templates.all(:type => "NS")
      
      return false if template_ns.length != nservers.length

      nservers.each do |ns|
        return false unless template_ns.all(:content => /^#{Regexp.escape(ns.name.to_s)}\.?$/).any?
      end
    end
    return true
  end

  private

  # check if domain already exist
  def exist?(domain)
    Domain.all(:name => domain).any?
  end

  # create new record in Domain table
  def new_domain(domain)
    d = Domain.new
    d.name = domain
    d.type = "NATIVE"

    d.save
    return d
  end

  # create new record in Zone table
  def new_zone(domain_id)
    z = Zone.new
    z.domain_id = domain_id
    z.owner = User.all(:username => "admin").first.id

    z.save
    return z
  end

  # create new record in Record table
  def new_record(template, domain, record)
    r = Record.new

    r.domain_id = domain.id
    r.name = subst(domain, template.name)
    
    if template.type == "A" || template.type == "CNAME" || template.type == "AAAA"
      r.name += "." unless template.name.empty?
      r.name += domain.name
    end
    
    r.type = template.type
    
    if template.type == "A" || template.type == "AAAA"
      unless record[1].empty?
        r.content = record[1]
      else 
        r.content = template.content
        record[1] = template.content
      end
    else
      r.content = subst(domain, template.content)
    end

    r.ttl = template.ttl
    r.prio = template.prio
    r.change_date = Time.now.to_i
    
    r.save
    return r
  end

  # substitute [ZONE] and [SERIAL] and return it
  def subst(domain, text)
    stext = text.gsub /\[ZONE\]/, domain.name
    stext.gsub! /\[SERIAL\]/, Time.now.strftime("%Y%m%d00")
    return stext
  end
end
