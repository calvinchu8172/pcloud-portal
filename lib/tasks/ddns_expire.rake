namespace :ddns_expire do
  desc "create fake data for test"

  DOMAIN = "@example.com"
  NOW_USER = "now"
  NOW_USER_EMAIL = NOW_USER + DOMAIN

  EXPIRE60_USER = "expire60"
  EXPIRE60_USER_EMAIL = EXPIRE60_USER + DOMAIN

  EXPIRE90_USER = "expire90"
  EXPIRE90_USER_EMAIL = EXPIRE90_USER + DOMAIN


  task create_fake: :environment do
    # create a ddns record last active now
    create_data(NOW_USER_EMAIL, "1.1.1.1", NOW_USER, Time.now.to_i, Time.now.to_i - 1)

    # create a ddns record last active 60 days ago
    create_data(EXPIRE60_USER_EMAIL, "2.2.2.2", EXPIRE60_USER, 65.days.ago.to_i, 60.days.ago.to_i)

    # create a ddns record last active 90 days ago
    create_data(EXPIRE90_USER_EMAIL, "3.3.3.3", EXPIRE90_USER, 100.days.ago.to_i, 90.days.ago.to_i)
  end

  def create_data(email, ip, hostname, signin_time, signout_time)
    return puts "#{email} has been existed." if User.find_by(email: email)

    user = FactoryGirl.build(:api_user, email: email)
    user.skip_confirmation!
    user.save

    device = FactoryGirl.create(:api_device, product: Product.first)
    pairing = FactoryGirl.create(:pairing, user_id: user.id, device_id: device.id)
    ddns = FactoryGirl.create(:ddns, ip_address: ip, hostname: hostname, domain: Domain.first, device: device)
    xmpp_last = XmppLast.create(username: device.xmpp_username, last_signin_at: signin_time, last_signout_at: signout_time, state: "")
    puts "Create record: #{user.email}"

    create_route53_record(ddns)
  end

  def create_route53_record(ddns)
    route = AWS::Route53.new

    zone_id = Settings.environments.zones_info.id
    ddns_name = Settings.environments.ddns + '.'
    target_name = ddns.hostname + "." + ddns_name

    hosted_zone = route.hosted_zones[zone_id]
    rrsets = hosted_zone.rrsets

    begin
      rrset = rrsets.create(target_name, 'A', ttl: 300, resource_records: [{value: ddns.get_ip_addr}])
      puts "  Create DDNS record: #{rrset.name}"
      puts "                  ip: #{rrset.resource_records.first[:value]}"
    rescue Exception => error
      puts error
    end
  end

  desc "delete fake data"
  task delete_fake: :environment do

    delete_data(NOW_USER_EMAIL)
    delete_data(EXPIRE60_USER_EMAIL)
    delete_data(EXPIRE90_USER_EMAIL)

  end

  def delete_data(email)
    user = User.find_by(email: email)
    return if user.nil?
    return if user.devices.first.nil?

    device = Api::Device.find(user.devices.first.id)
    ddns = Ddns.find_by(device: device)
    pairing = Pairing.find_by(device: device)
    xmpp_last = XmppLast.find_by(username: device.xmpp_username)

    xmpp_last.destroy if xmpp_last
    ddns.destroy if ddns
    pairing.destroy if pairing
    device.destroy if device
    user.destroy if user
    puts "Delete record: #{user.email}"

    delete_route53_record(ddns)
  end

  def delete_route53_record(ddns)
    route = AWS::Route53.new

    zone_id = Settings.environments.zones_info.id
    ddns_name = Settings.environments.ddns + '.'
    target_name = ddns.hostname + "." + ddns_name

    hosted_zone = route.hosted_zones[zone_id]
    rrsets = hosted_zone.rrsets

    begin
      rrset = rrsets[target_name, 'A']
      info = rrset.delete
      puts "  Delete DDNS record: #{rrset.name}, status: #{info.status}"
    rescue Exception => error
      puts error
    end
  end

  desc "check result after processing"
  task test_fake: :environment do
    check_ddns_record(NOW_USER_EMAIL)
    check_ddns_record(EXPIRE60_USER_EMAIL)
    check_ddns_record(EXPIRE90_USER_EMAIL)
  end

  def check_ddns_record(email)
    user = User.find_by(email: email)
    return puts "Error: #{email} not found" if user.nil?

    pairing = Pairing.find_by(user: user)
    return puts "Error: #{email} pairing not found" if pairing.nil?

    ddns = Ddns.find_by(device: pairing.device)
    if ddns
      puts "Error: #{user.email} DDNS record still exists."
    else
      puts "Success: #{user.email} DDNS record has been deleted."
    end
  end


  task :notice => :environment do
    # job_last_scan_time # wait for design

    Services::DdnsExpire.notice

  end

  task :delete => :environment do
    Services::DdnsExpire.delete
  end

end
