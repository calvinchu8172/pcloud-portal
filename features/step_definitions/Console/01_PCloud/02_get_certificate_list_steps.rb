
Given(/^Server has an Certifcate data as below:$/) do |cert_json|
  cert = Api::Certificate.new(JSON.parse(cert_json))
  cert.save
end

When(/^client send a GET request to \/v1\/device_certs with:$/) do |table|
  data = table.rows_hash
  path = '//' + Settings.environments.api_domain + "/v1/device_certs"

  params = {}
  if data["certificate_serial"].present?
    cert_serial = data["certificate_serial"].include?("INVALID") ? data["certificate_serial"] : @certificate.serial
    params["certificate_serial"] = cert_serial
  end

  if data["timestamp"].present?
    timestamp = data["timestamp"].include?("INVALID") ? ( Time.now.to_i - 350 ) : Time.now.to_i
    header 'X-Timestamp', timestamp
  end

  if data["signature"].present?
    signature = data["signature"].include?("INVALID") ? data["signature"] : create_signature_urlsafe(timestamp, cert_serial)
    header 'X-Signature', signature
  end
  get path, params

  puts last_response.body
end
