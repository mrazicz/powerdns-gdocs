class PdnsController
  require "data_mapper"
  require "classes/models"
  
  def initialize(db, pdns)
    DataMapper.setup(:default, {
      :adapter  => db["adapter"],
      :host     => db["host"],
      :username => db["username"],
      :password => db["password"],
      :database => db["database"]
    })    
    
    DataMapper.finalize
    
    @template = ZoneTempl.all(:name => pdns["template"]).zone_templ_records
  end
  
  def add(record)
    unless exist?(record[0])
      domain = new_domain(record[0])
      zone = new_zone(domain.id)
      for t in @template
        r = Record.new
        
        r_name = t.name.gsub /\[ZONE\]/, domain.name
        r_name.gsub! /\[SERIAL\]/, Time.now.strftime("%Y%m%d00")
        r_content = t.content.gsub /\[ZONE\]/, domain.name
        r_content.gsub! /\[SERIAL\]/, Time.now.strftime("%Y%m%d00")

        r.domain_id = domain.id
        
        r.name = r_name
        if t.type == "A" || t.type == "CNAME"
          r.name += "." unless t.name.empty?
          r.name += domain.name
        end

        r.type = t.type
        r.content = r_content
        r.ttl = t.ttl
        r.prio = t.prio
        r.change_date = Time.now.to_i

        r.save
      end
    end
  end


  private

  def exist?(domain)
    Domain.all(:name => domain).any?
  end

  def new_domain(domain)
    d = Domain.new
    d.name = domain
    d.type = "NATIVE"

    d.save
    return d
  end

  def new_zone(domain_id)
    z = Zone.new
    z.raise_on_save_failure = true
    z.domain_id = domain_id
    z.owner = 1
    
    z.save
    return z
  end
end
