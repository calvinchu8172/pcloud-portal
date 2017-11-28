When(/^client send a DELETE request to \/v(\d+)\/templates\/:identity with:$/) do |arg1, table|
  @template = @templates[0]
  data = table.rows_hash
  path = '//' + Settings.environments.api_domain + "/v1/templates/#{@template.identity}"

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
    signature = create_signature_urlsafe(timestamp, certificate_serial, @template.identity)
  end

  header 'X-Signature', signature
  header 'X-Timestamp', timestamp

  qs = {
    certificate_serial: certificate_serial,
    identity: @template.identity
  }

  qs.delete_if {|key, value| value.nil? }

  delete path, qs
end

When(/^client send a DELETE request to \/v(\d+)\/templates\/:invalid_identity with:$/) do |arg1, table|
  data = table.rows_hash
  path = '//' + Settings.environments.api_domain + "/v1/templates/invalid_identity"

  certificate_serial = @certificate.serial
  timestamp = Time.now.to_i
  signature = create_signature_urlsafe(timestamp, certificate_serial, 'invalid_identity')

  header 'X-Signature', signature
  header 'X-Timestamp', timestamp

  qs = {
    certificate_serial: certificate_serial,
    identity: 'invalid_identity'
  }

  delete path, qs
end

Then(/^the template should be deleted$/) do
  expect(Template.find_by(identity: @template.identity)).to eq nil
end
