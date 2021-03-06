class PdnsController
  require "data_mapper"
  require "models"
  require "resolv"

  # constructor
  def initialize(db, pdns, mxgoogle)
    DataMapper.setup(:default, {
      :adapter  => db["adapter"],
      :host     => db["host"],
      :username => db["username"],
      :password => db["password"],
      :database => db["database"]
    })

    DataMapper.finalize

    @templates = ZoneTempl.all(:name => pdns["template"]).zone_templ_records
    @mxgoogle = mxgoogle
  end

  # add new record to db
  def add(record)
    unless exist?(record[0])
      domain = new_domain(record[0])
      zone = new_zone(domain.id)
      for t in @templates
        new_record(t, domain, record)
      end

      if(record[4] == "yes")
        @mxgoogle.each do |content, ttl_prio|
          new_mx_record(domain, content, ttl_prio["ttl"], ttl_prio["prio"])
        end

        new_txt_record(domain, record[5]) unless record[5].empty?
      end

      return record
    else
      update(record)
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

  # update record
  def update(record)
    domain = Domain.all(:name => record[0]).last
    dbrecords = Record.all(:domain_id => domain.id)

    a_record = dbrecords.all(:type => 'A')[0]
    a_record.update(:content => record[1]) \
      if a_record.content != record[1] && a_record

    mx_records = dbrecords.all(:type => 'MX')
    mx_records.destroy if mx_records.any? && record[4].blank?
    if record[4] == 'yes'
      @mxgoogle.each do |content, ttl_prio|
        mxr = mx_records.all(:content => record[4])[0]
        new_mx_record(domain, content, ttl_prio["ttl"], ttl_prio["prio"]) \
          unless mxr
      end
    end

    txt_record = dbrecords.all(:type => 'TXT')[0]
    txt_record.destroy if txt_record && record[5].blank?
    txt_record.update(:content => record[5]) \
      if txt_record && !record[5].blank? && txt_record.content != record[5]
    new_txt_record(domain, record[5]) if !txt_record && !record[5].blank?
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

  # create new MX google record in Record table
  def new_mx_record(domain, content, ttl, prio)
    r = Record.new

    r.domain_id = domain.id
    r.name = domain.name
    r.type = "MX"
    r.content = content
    r.ttl = ttl
    r.prio = prio
    r.change_date = Time.now.to_i

    r.save
    return r
  end

  # create new TXT record in Record table
  def new_txt_record(domain, content)
    r = Record.new

    r.domain_id = domain.id
    r.name = domain.name
    r.type = "TXT"
    r.content = content
    r.ttl = 3600
    r.prio = 0
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

