Given(/^The app table already exists$/) do
  # data = {
  #   "code": "ResourceInUseException",
  #   "message": "Table already exists: alpha-object-storage-service-2b0fca18d0182e26b51014ec11b4cc58ebb7b28b3e10206163ef0a4c2306bd6f"
  # }
  env = Settings.oss.env
  service = Settings.oss.service_name
  table_name = "#{env}-#{service}-client-id"
  puts table_name

  allow_any_instance_of(Api::Console::V1::Oauth2::ApplicationsController).to receive(:create_dynamo_db)
    .with(@oauth_client_apps[0].uid)
    .and_raise(ApiError.new('ResourceInUseException'), "Table already exists: #{table_name}")
end

When(/^client send a POST request to \/v(\d+)\/oauth(\d+)\/applications\/:id\/create_table with:$/) do |arg1, arg2, table|
  @oauth_client_app = @oauth_client_apps[0]
  data = table.rows_hash
  path = '//' + Settings.environments.api_domain + "/v1/oauth2/applications/#{@oauth_client_app.id}/create_table"

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

  body = {
    certificate_serial: certificate_serial
  }

  body.delete_if {|key, value| value.nil? }

  post path, body
end

When(/^client send a POST request to \/v(\d+)\/oauth(\d+)\/applications\/:invalid_id\/create_table with:$/) do |arg1, arg2, table|

  data = table.rows_hash
  path = '//' + Settings.environments.api_domain + "/v1/oauth2/applications/invalid_id/create_table"

  certificate_serial = @certificate.serial
  timestamp = Time.now.to_i
  signature = create_signature_urlsafe(timestamp, certificate_serial, 'invalid_id')

  header 'X-Signature', signature
  header 'X-Timestamp', timestamp

  body = {
    certificate_serial: certificate_serial
  }

  post path, body
end

class ApiError < StandardError
  attr_reader :code

  def initialize(code)
   super
   @code = code
  end
end
