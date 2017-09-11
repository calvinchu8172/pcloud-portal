When(/^client send a POST request to \/console\/device_certs with:$/) do |table|
  data = table.rows_hash
  path = '//' + Settings.environments.api_domain + "/console/device_certs"

  params = {}
  cert_serial, description, content = nil
  unless data["certificate_serial"].blank?   
    cert_serial = data["certificate_serial"].include?("INVALID") ? data["certificate_serial"] : @certificate.serial
    params["certificate_serial"] = cert_serial 
  end
  
  unless data["description"].blank?   
    description = data["description"] 
    params["description"] = description
  end

  unless data["content"].blank?   
    content = data["content"].include?("INVALID") ? data["content"] : @certificate.content
    params["content"] = content
  end

  # binding.pry
  signature = data["signature"].include?("INVALID") ? data["signature"] : create_signature_urlsafe(cert_serial, content, description)
  header 'X-Signature', signature
  post path, params
end