

# ------------------------------------- #
# -------- device registration -------- #
# ------------------------------------- #


# ------------------------ #
# -------- others -------- #
# ------------------------ #

Given(/^an existing user's account and password$/) do
  @user = FactoryGirl.create(:api_user,
    email: "acceptance@ecoworkinc.com",
    password: "secret123",
    password_confirmation: "secret123")
end

Then(/^the JSON response should include:$/) do |attributes|
  body_hash = JSON.parse(last_response.body)
  attributes = JSON.parse(attributes)

  attributes.each do |attribute|
    expect(body_hash.key?(attribute)).to be true
  end
end

Given(/^an existing user with:$/) do |table|
  data = table.rows_hash
  email = data["id"]
  password = data["password"]
  FactoryGirl.create(:api_user, email: email, password: password, password_confirmation: password)
end

Given(/^a signed in client$/) do
  @user = TestingHelper.create_and_confirm(FactoryGirl.create(:api_user))
end

Then(/^the JSON response should include (\d+):$/) do |record_count, attributes|

  body_array = JSON.parse(last_response.body)
  expect(body_array.count).to eq(record_count.to_i)

  attributes = JSON.parse(attributes)

  body_array.each do |body|
    attributes.each do |attribute|
      expect(body.key?(attribute)).to be true
    end
  end
end

Then(/^the response status should be "(.*?)"$/) do |status_code|
  expect(last_response.status).to eq(status_code.to_i)
end

Then(/^the JSON response should include valid invitation_key$/) do
  body = JSON.parse(last_response.body)
  expect(body["invitation_key"]).to eq(Invitation.first.key)
end

Then(/^the JSON response should include error code: "(.*?)"$/) do |error_code|
  body = JSON.parse(last_response.body)
  expect(body["error_code"]).to eq(error_code)
end

Then(/^the JSON response should include description: "(.*?)"$/) do |description|
  body = JSON.parse(last_response.body)
  expect(body["description"]).to eq(description)
end

Given(/^an existing certificate and RSA key$/) do
  create_certificate_and_rsa_key
end

Then(/^the JSON response should be$/) do |response|
  expect(JSON.parse(last_response.body)).to eq(JSON.parse(response))
end

Then(/^Email deliveries should be (\d+)$/) do |count|
  expect(ActionMailer::Base.deliveries.count).to eq(count.to_i)
end

Then(/^the API should return "(.*?)" and "(.*?)" with "(.*?)" responds$/) do |http, json, type|
  api_result = JSON.parse(last_response.body)
  expect(last_response.status).to eq(http.to_i)
  key = "error" if type == "error"
  key = "result" if type == "failure"
  expect(api_result[key]).to eq(json)
end

Then(/^the device record in database should have the same IP$/) do
  @record = Device.find_by(mac_address: @device_given_attrs["mac_address"])
  decoded_ip = IPAddr.new(@record.ip_address.to_i(16), Socket::AF_INET).to_s
  expect(decoded_ip).to eq(ENV['RAILS_TEST_IP_ADDRESS']), "expected #{ENV['RAILS_TEST_IP_ADDRESS']}, but got #{decoded_ip}"
end


# --------------------------- #
# -------- functions -------- #
# --------------------------- #

def create_certificate_and_rsa_key
  @rsa_key = OpenSSL::PKey::RSA.new(2048)
  name = OpenSSL::X509::Name.parse 'CN=nobody/DC=example'

  cert = OpenSSL::X509::Certificate.new
  cert.version = 2
  cert.serial = 0
  cert.not_before = Time.now
  cert.not_after = Time.now + 365*24*60*60

  cert.public_key = @rsa_key.public_key
  cert.subject = name

  cert.sign(@rsa_key, OpenSSL::Digest::SHA1.new)

  @certificate = Api::Certificate.create(serial: "serial_name", content: cert.to_pem, vendor_id: 1)
end

def create_signature(*arg)
  data = arg.map { |param| param.to_s}.join('')

  digest = OpenSSL::Digest::SHA224.new
  private_key = @rsa_key
  #signature = CGI::escape(Base64::encode64(private_key.sign(digest, data)))
  signature = Base64::encode64(private_key.sign(digest, data))
end

def check_authentication_token(authentication_token)
  if authentication_token == "VALID AUTHENTICATION TOKEN"
    authentication_token = @user.create_authentication_token
  elsif authentication_token == "VALID ACCESS TOKEN"
    access_token = Doorkeeper::AccessToken.create(:application_id => 1, :resource_owner_id => @user.id, :expires_in => 21600, scopes: "")
    authentication_token = access_token.token
  elsif authentication_token == "REVOKED ACCESS TOKEN"
    access_token = Doorkeeper::AccessToken.create(:application_id => 1, :resource_owner_id => @user.id, :expires_in => 21600, :revoked_at => Time.now, scopes: "")
    authentication_token = access_token.token
  elsif authentication_token == "EXPIRED ACCESS TOKEN"
    access_token = Doorkeeper::AccessToken.create(:application_id => 1, :resource_owner_id => @user.id, :expires_in => 21600, :created_at => Time.at(Time.now.to_i - 21700), scopes: "")
    authentication_token = access_token.token
  elsif authentication_token.include?("INVALID")
    authentication_token = ""
  else
    authentication_token = ""
  end
end

def reset_signature(device)
  magic_number = Settings.magic_number
  data = device["mac_address"] + device["serial_number"].to_s + device["model_name"] + device["firmware_version"] + magic_number.to_s
  sha224 = OpenSSL::Digest::SHA224.new
  @device_given_attrs["signature"] = sha224.hexdigest(data)
  @device_given_attrs
end

# 建立 device 的 pairing 資料
def create_device_pairing(device)
  pairing = Pairing.new
  pairing.device = device
  pairing.user = TestingHelper.create_and_signin
  pairing.ownership = 0
  pairing.save
end


