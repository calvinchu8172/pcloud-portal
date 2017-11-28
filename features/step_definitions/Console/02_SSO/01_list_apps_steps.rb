When(/^client send a GET request to \/v(\d+)\/oauth2\/applications with:$/) do |arg1, table|
  data = table.rows_hash
  path = '//' + Settings.environments.api_domain + "/v1/oauth2/applications"

  if data["certificate_serial"].nil?
    certificate_serial = nil
  elsif data["certificate_serial"].include?("INVALID")
    certificate_serial = "invalid certificate_serial"
  else
    certificate_serial = @certificate.serial
  end

  if data["timestamp"].nil?
    timestamp = nil
  elsif data["timestamp"].include?("INVALID")
    timestamp = Date.new(2017,9,6).to_time.to_i
  else
    timestamp = Time.now.to_i
  end

  if data["signature"].nil?
    signature = nil
  elsif data["signature"].include?("INVALID")
    signature = "invalid signature"
  else
    signature = create_signature_urlsafe(timestamp, certificate_serial)
  end

  header 'X-Signature', signature
  header 'X-Timestamp', timestamp

  qs = {
    certificate_serial: certificate_serial
  }

  qs.delete_if {|key, value| value.nil? }

  get path, qs
end

Then(/^the JSON response should have app list$/) do
  body_hash = JSON.parse(last_response.body)['data'].each do |app|
    @oauth_client_apps.each do |app|
      expect(Doorkeeper::Application.exists?(name: app.name)).to be true
    end
  end
end

Given(/^(\d+) existing client app$/) do |count|
  @oauth_client_apps = []
  count.to_i.times do |i|
    @oauth_client_apps << FactoryGirl.create(:oauth_client_app)
  end
end
