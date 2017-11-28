When(/^client send a POST request to \/v1\/device_certs with:$/) do |table|
  data = table.rows_hash
  path = '//' + Settings.environments.api_domain + "/v1/device_certs"

  params = {}
  cert_serial, description, content = nil
  if data["certificate_serial"].present?
    cert_serial = data["certificate_serial"].include?("INVALID") ? data["certificate_serial"] : @certificate.serial
    params["certificate_serial"] = cert_serial
  end

  if data["description"].present?
    description = data["description"]
    params["description"] = description
  end

  if data["content"].present?
    content = data["content"].include?("INVALID") ? data["content"] : @certificate.content
    params["content"] = content
  end

  if data["timestamp"].present?
    timestamp = data["timestamp"].include?("INVALID") ? ( Time.now.to_i - 350 ): Time.now.to_i
    header 'X-Timestamp', timestamp
  end

  if data["signature"].present?
    signature = data["signature"].include?("INVALID") ? data["signature"] : create_signature_urlsafe(timestamp, cert_serial, content, description)
    header 'X-Signature', signature
  end
  post path, params
end
