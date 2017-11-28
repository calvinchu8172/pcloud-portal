When(/^client send a GET request to \/v(\d+)\/oauth(\d+)\/applications\/:id with:$/) do |arg1, arg2, table|
  @oauth_client_app = @oauth_client_apps[0]
  # client_id = @oauth_client_app.uid
  id = @oauth_client_app.id
  data = table.rows_hash
  path = '//' + Settings.environments.api_domain + "/v1/oauth2/applications/#{@oauth_client_app.id}"

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
    signature = create_signature_urlsafe(timestamp, certificate_serial, id)
  end

  header 'X-Signature', signature
  header 'X-Timestamp', timestamp

  qs = {
    certificate_serial: certificate_serial
  }

  qs.delete_if {|key, value| value.nil? }

  get path, qs
end

When(/^client send a GET request to \/v(\d+)\/oauth(\d+)\/applications\/:invalid_id with:$/) do |arg1, arg2, table|
  data = table.rows_hash
  path = '//' + Settings.environments.api_domain + "/v1/oauth2/applications/invalid_id"

  certificate_serial = @certificate.serial
  timestamp = Time.now.to_i
  signature = create_signature_urlsafe(timestamp, certificate_serial, 'invalid_id')

  header 'X-Signature', signature
  header 'X-Timestamp', timestamp

  qs = {
    certificate_serial: certificate_serial
  }

  get path, qs
end

Then(/^the JSON response should have app info$/) do
  body_hash = JSON.parse(last_response.body)['data']
  expect(body_hash['name']).to eq Doorkeeper::Application.find_by(uid: @oauth_client_app.uid).name
end
