When(/^an template exists with template contents$/) do
  @template = FactoryGirl.create(:template)
  @template_content = FactoryGirl.create(:template_content, template_id: @template.id)
end

When(/^client send a POST request to \/d\/3\/notifications with:$/) do |table|
    data = table.rows_hash
    path = '//' + Settings.environments.api_domain + "/d/3/notifications"
    if data["mac_address"].nil?
      mac_address = nil
    else
      mac_address = data["mac_address"].include?("INVALID") ? "invalid_mac_address" : @device.mac_address
    end
    if data["serial_number"].nil?
      serial_number = nil
    else
      serial_number = data["serial_number"].include?("INVALID") ? "invalid_serial_number" : @device.serial_number
    end
    if data["template_id"].nil?
      template_identity = nil
    else
      template_identity = data["template_id"].include?("INVALID") ? "invalid_template_identity" : @template.identity
    end
    if data["template_params"].nil?
      template_params = nil
    else
      template_params = data["template_params"].include?("INVALID") ? "invalid_template_params" : {a: "param1", b: "param2"}.to_json
      template_params = data["template_params"].include?("NOT MATCHED") ? {a: "param1"}.to_json : template_params
    end
    if data["certificate_serial"].nil?
      certificate_serial = nil
    else
      certificate_serial = data["certificate_serial"].include?("INVALID") ? "invalid_certificate_serial" : @certificate.serial
    end
    if data["app_group_id"].nil?
      app_group_id = nil
    else
      app_group_id = data["app_group_id"].include?("INVALID") ? "invalid_app_group_id" : "app_group_id"
    end
    if data["timestamp"].nil?
      timestamp = nil
    else
      timestamp = data["timestamp"].include?("INVALID") ? (Time.now.utc.to_i - 3000) : Time.now.utc.to_i
    end
    if data["signature"].nil?
      signature = nil
    else
      signature = data["signature"].include?("INVALID") ? "invalid_signature" : create_signature_urlsafe(timestamp, app_group_id, certificate_serial, mac_address, serial_number, template_identity, template_params)
    end

    header 'X-Timestamp', timestamp
    header 'X-Signature', signature

    body = {
      mac_address: mac_address,
      serial_number: serial_number,
      template_id: template_identity,
      template_params: template_params,
      certificate_serial: certificate_serial,
      app_group_id: app_group_id
    }
    body.delete_if {|key, value| value.nil? }

    post path, body
  end

  And(/^the JSON response should include key "(.*?)"$/) do |column_name|
    expect(JSON.parse(last_response.body)).to have_key("request_id")
  end
