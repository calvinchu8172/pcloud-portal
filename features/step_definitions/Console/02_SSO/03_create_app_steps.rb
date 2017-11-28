Given(/^Dynamo_DB will successfully create table$/) do
  # @oauth_client_app = @oauth_client_apps[0]
  allow_any_instance_of(Api::Console::V1::Oauth2::ApplicationsController).to receive(:create_dynamo_db).and_return('successfully create table')
end

When(/^client send a POST request to \/v(\d+)\/oauth(\d+)\/applications with:$/) do |arg1, arg2, table|
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

  if data["name"].nil?
    @name = nil
  elsif data["name"].include?("INVALID")
    @name = "invalid name"
  else
    @name = 'oauth_client_app_test'
  end

  if data["scopes"].nil?
    @scopes = ''
  elsif data["scopes"].include?("INVALID")
    @scopes = "invalid scopes"
  else
    @scopes = "all show create update"
  end

  if data["redirect_uri"].nil?
    @redirect_uri = nil
  elsif data["redirect_uri"].include?("INVALID")
    @redirect_uri = "invalid redirect_uri"
  else
    @redirect_uri =
    "https://app1.com/callback
    https://app2.com/callback"
  end

  if data["logout_redirect_uri"].nil?
    @logout_redirect_uri = nil
  elsif data["logout_redirect_uri"].include?("INVALID")
    @logout_redirect_uri = "invalid logout_redirect_uri"
  else
    @logout_redirect_uri =
    "https://app1.com
    https://app2.com"
  end

  if data["create_table"].nil?
    create_table = nil
  elsif data["create_table"].include?("INVALID")
    create_table = "invalid create_db"
  elsif data["create_table"] == '1'
    create_table = "1"
  elsif data["create_table"] == '0'
    create_table = "0"
  end

  if data["signature"].nil?
    signature = nil
  elsif data["signature"].include?("INVALID")
    signature = "invalid signature"
  else
    signature = create_signature_urlsafe(timestamp, certificate_serial, create_table, @logout_redirect_uri, @name, @redirect_uri, @scopes)
  end

  header 'X-Signature', signature
  header 'X-Timestamp', timestamp

  body = {
    certificate_serial: certificate_serial,
    name: @name,
    scopes: @scopes,
    redirect_uri: @redirect_uri,
    logout_redirect_uri: @logout_redirect_uri,
    create_table: create_table
  }

  body.delete_if {|key, value| value.nil? }

  post path, body
end

Then(/^the JSON response should have new app info$/) do
  body_hash = JSON.parse(last_response.body)['data']
  expect(body_hash['name']).to eq @name
  expect(body_hash['redirect_uri']).to eq @redirect_uri
  expect(body_hash['scopes'].join(' ')).to eq @scopes
  expect(body_hash['logout_redirect_uri']).to eq @logout_redirect_uri
end
