When(/^client send a PUT request to \/v(\d+)\/oauth(\d+)\/applications\/:id with:$/) do |arg1, arg2, table|

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

  if data["name"].nil?
    @name = nil
  elsif data["name"].include?("INVALID")
    @name = "invalid name"
  else
    @name = 'oauth_client_app_modify'
  end

  if data["scopes"].nil?
    scopes = nil
  elsif data["scopes"].include?("INVALID")
    scopes = "invalid scopes"
  else
    @scopes = "all show create update destroy"
  end

  if data["redirect_uri"].nil?
    @redirect_uri = nil
  elsif data["redirect_uri"].include?("INVALID")
    @redirect_uri = "invalid redirect_uri"
  else
    @redirect_uri =
    "https://app1_modify.com/callback
    https://app2_modify.com/callback"
  end

  if data["logout_redirect_uri"].nil?
    @logout_redirect_uri = nil
  elsif data["logout_redirect_uri"].include?("INVALID")
    @logout_redirect_uri = "invalid logout_redirect_uri"
  else
    @logout_redirect_uri =
    "https://app1_modify.com
    https://app2_modify.com"
  end

  if data["signature"].nil?
    signature = nil
  elsif data["signature"].include?("INVALID")
    signature = "invalid signature"
  else
    signature = create_signature_urlsafe(timestamp, certificate_serial, @oauth_client_app.id, @logout_redirect_uri, @name, @redirect_uri, @scopes)
  end

  header 'X-Signature', signature
  header 'X-Timestamp', timestamp

  body = {
    certificate_serial: certificate_serial,
    name: @name,
    scopes: @scopes,
    redirect_uri: @redirect_uri,
    logout_redirect_uri: @logout_redirect_uri
  }

  body.delete_if {|key, value| value.nil? }

  put path, body
end

When(/^client send a PUT request to \/v(\d+)\/oauth(\d+)\/applications\/:invalid_id with:$/) do |arg1, arg2, table|
  data = table.rows_hash
  path = '//' + Settings.environments.api_domain + "/v1/oauth2/applications/invalid_id"
  certificate_serial = @certificate.serial
  timestamp = Time.now.to_i
  @name = 'oauth_client_app_modify'
  @scopes = "all show create update destroy"
  @redirect_uri =
  "https://app1_modify.com/callback
  https://app2_modify.com/callback"
  @logout_redirect_uri =
  "https://app1_modify.com
  https://app2_modify.com"
  signature = create_signature_urlsafe(timestamp, certificate_serial, 'invalid_id', @logout_redirect_uri, @name, @redirect_uri, @scopes)

  header 'X-Signature', signature
  header 'X-Timestamp', timestamp

  body = {
    certificate_serial: certificate_serial,
    name: @name,
    scopes: @scopes,
    redirect_uri: @redirect_uri,
    logout_redirect_uri: @logout_redirect_uri
  }

  put path, body
end

Then(/^the JSON response should have updated app info$/) do
  body_hash = JSON.parse(last_response.body)['data']
  expect(body_hash['name']).to eq @name
  expect(body_hash['redirect_uri']).to eq @redirect_uri
  expect(body_hash['scopes']).to eq @scopes.split(' ')
  expect(body_hash['logout_redirect_uri']).to eq @logout_redirect_uri
end
