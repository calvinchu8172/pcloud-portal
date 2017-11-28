Given(/^Dynamo_DB will successfully delete table$/) do
  allow_any_instance_of(Api::Console::V1::Oauth2::ApplicationsController).to receive(:delete_dynamo_db).with(@oauth_client_apps[0].uid).and_return('successfully delete db')
end

When(/^client send a DELETE request to \/v(\d+)\/oauth(\d+)\/applications\/:id with:$/) do |arg1, arg2, table|
  @oauth_client_app = @oauth_client_apps[0]
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
    signature = create_signature_urlsafe(timestamp, certificate_serial, @oauth_client_app.id)
  end

  header 'X-Signature', signature
  header 'X-Timestamp', timestamp

  qs = {
    certificate_serial: certificate_serial
  }

  qs.delete_if {|key, value| value.nil? }

  delete path, qs
end

When(/^client send a DELETE request to \/v(\d+)\/oauth(\d+)\/applications\/:invalid_id with:$/) do |arg1, arg2, table|
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

  delete path, qs
end

Then(/^the app should be deleted$/) do
  expect(Doorkeeper::Application.find_by(uid: @oauth_client_app.uid)).to eq nil
end
