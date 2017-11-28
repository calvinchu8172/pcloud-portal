When(/^client send a GET request to \/v(\d+)\/templates\/:identity with:$/) do |arg1, table|
  @template = @templates[0]
  identity = @template.identity
  data = table.rows_hash
  path = '//' + Settings.environments.api_domain + "/v1/templates/#{identity}"

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
    signature = create_signature_urlsafe(timestamp, certificate_serial, identity)
  end

  header 'X-Signature', signature
  header 'X-Timestamp', timestamp

  qs = {
    certificate_serial: certificate_serial
  }

  qs.delete_if {|key, value| value.nil? }

  get path, qs
end

When(/^client send a GET request to \/v(\d+)\/templates\/:invalid_identity with:$/) do |arg1, table|
  data = table.rows_hash
  path = '//' + Settings.environments.api_domain + "/v1/templates/invalid_identity"

  certificate_serial = @certificate.serial
  timestamp = Time.now.to_i
  signature = create_signature_urlsafe(timestamp, certificate_serial, 'invalid_identity')

  header 'X-Signature', signature
  header 'X-Timestamp', timestamp

  qs = {
    certificate_serial: certificate_serial
  }

  get path, qs
end

Then(/^the JSON response should have template info$/) do
  body_hash = JSON.parse(last_response.body)['data']
  expect(body_hash['identity']).to eq @template.identity
  template_content_locales = []
  @template.template_contents.each do |template_content|
    template_content_locales << template_content.locale
  end
  expect(template_content_locales).to eq(available_locales)
end
