Given(/^(\d+) existing template$/) do |count|
  @templates = []
  count.to_i.times do |i|
    @templates << template = FactoryGirl.create(:template)
    available_locales.map do |locale|
      template_content = FactoryGirl.create(:template_content, template_id: template.id, locale: locale, title: "#{locale}_title", content: "#{locale}_content")
    end
  end
end

When(/^client send a GET request to \/v(\d+)\/templates with:$/) do |arg1, table|
  data = table.rows_hash
  path = '//' + Settings.environments.api_domain + "/v1/templates"

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
    signature = create_signature_urlsafe(timestamp, certificate_serial)
  end

  header 'X-Signature', signature
  header 'X-Timestamp', timestamp

  qs = {
    certificate_serial: certificate_serial
  }

  qs.delete_if {|key, value| value.nil? }

  get path, qs
end

Then(/^the JSON response should have template list$/) do
  body_hash = JSON.parse(last_response.body)['data'].each do |each_template|
    @templates.each do |template|
      expect(Template.exists?(identity: template.identity)).to be true
      template_content_locales = []
      template.template_contents.each do |template_content|
        template_content_locales << template_content.locale
      end
      expect(template_content_locales).to eq(available_locales)
    end
  end
end

def available_locales
  ['cs', 'de', 'en', 'es', 'fr', 'hu', 'it', 'nl', 'pl', 'ru', 'th', 'tr', 'zh-TW']
end
