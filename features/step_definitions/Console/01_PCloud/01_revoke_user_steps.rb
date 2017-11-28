Given(/^an existing access grand$/) do
   @oauth_grant_code = FactoryGirl.create(:access_grant, resource_owner_id: @user.id, application_id: @oauth_client_app.id)
end

Given(/^user accepted invitation before$/) do
  @accepted_user = FactoryGirl.create(:accepted_user, invitation_id: @invitation.id, user_id: @user.id, status: 1)
end

When(/^client send a PUT request to \/v1\/user\/revoke with:$/) do |table|
  data = table.rows_hash
  path = '//' + Settings.environments.api_domain + "/v1/user/revoke"

  if data["email"].nil?
    email = nil
  elsif data["email"].include?("INVALID")
    email = "invalid email"
  else
    email = @user.email
  end

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
    signature = create_signature_urlsafe(timestamp, certificate_serial, email)
  end

  header 'X-Signature', signature
  header 'X-Timestamp', timestamp

  body = {
    email: email,
    certificate_serial: certificate_serial
  }

  body.delete_if {|key, value| value.nil? }

  put path, body

end

Then(/^the user email is changed to a secure random string$/) do
  expect(User.find(@user.id)).not_to eq(@user.email)
end

Then(/^the pairing is deleted$/) do
  expect(Pairing.find_by(user_id: @user.id).nil?).to eq(true)
end

Then(/^the accepted user is deleted$/) do
  expect(AcceptedUser.find_by(user_id: @user.id).nil?).to eq(true)
end

Then(/^the vendor device is deleted$/) do
  expect(VendorDevice.find_by(user_id: @user.id).nil?).to eq(true)
end

Then(/^the access grant is revoked$/) do
  expect(Doorkeeper::AccessGrant.find(@oauth_grant_code.id).revoked_at.present?).to eq(true)
end

Then(/^the access token is revoked$/) do
  expect(Doorkeeper::AccessToken.find(@oauth_access_token.id).revoked_at.present?).to eq(true)
end
