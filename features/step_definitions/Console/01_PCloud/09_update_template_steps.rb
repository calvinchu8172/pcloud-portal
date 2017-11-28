When(/^client send a PUT request to \/v(\d+)\/templates\/:identity with:$/) do |arg1, table|

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

  if data["identity"].nil?
    @identity = nil
  elsif data["identity"].include?("INVALID")
    @identity = "invalid identity"
  else
    @identity = @template.identity
  end

  if data["template_contents_attributes"].nil?
    template_contents_attributes = nil
  elsif data["template_contents_attributes"].include?("INVALID")
    template_contents_attributes = "invalid template_contents_attributes"
  else
    # template_contents_attributes = available_locales.each_with_index.map{ |x, i|
    template_contents_attributes = @template.template_contents.each_with_index.map{ |x, i|
      [
        i.to_s,
        {
          'id' => x.id.to_s,
          'locale' => x.locale,
          'title' => x.locale + '_title_modidy',
          'content' => x.locale + '_content_modify'
        }
      ]
    }.to_h
  end

  if data["signature"].nil?
    signature = nil
  elsif data["signature"].include?("INVALID")
    signature = "invalid signature"
  else
    signature = create_signature_urlsafe(timestamp, certificate_serial, @identity, template_contents_attributes)
  end

  header 'X-Signature', signature
  header 'X-Timestamp', timestamp

  body = {
    certificate_serial: certificate_serial,
    template_contents_attributes: template_contents_attributes
  }

  body.delete_if {|key, value| value.nil? }

  put path, body
end

When(/^client send a PUT request to \/v(\d+)\/templates\/:invalid_identity with:$/) do |arg1, table|
  data = table.rows_hash
  path = '//' + Settings.environments.api_domain + "/v1/templates/invalid_identity"
  certificate_serial = @certificate.serial
  timestamp = Time.now.to_i
  @template = @templates[0]
  template_contents_attributes = @template.template_contents.each_with_index.map{ |x, i|
      [
        i.to_s,
        {
          'id' => x.id.to_s,
          'locale' => x.locale,
          'title' => x.locale + '_title_modidy',
          'content' => x.locale + '_content_modify'
        }
      ]
    }.to_h

  signature = create_signature_urlsafe(timestamp, certificate_serial, 'invalid_identity', template_contents_attributes)

  header 'X-Signature', signature
  header 'X-Timestamp', timestamp

  body = {
    certificate_serial: certificate_serial,
    template_contents_attributes: template_contents_attributes
  }

  put path, body
end

Then(/^the JSON response should have updated template info$/) do
  body_hash = JSON.parse(last_response.body)['data']
  expect(body_hash['identity']).to eq @identity
  locale_array = []
  title_array = []
  content_array = []
  body_hash['template_contents'].map do |x|
    locale_array  << x['locale']
    title_array   << x['title']
    content_array << x['content']
  end
  expect(locale_array).to eq available_locales
  expect(title_array).to eq available_locales.map {|x| x + '_title_modidy' }
  expect(content_array).to eq available_locales.map {|x| x + '_content_modify' }
end
