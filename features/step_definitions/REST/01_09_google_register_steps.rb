Given(/^the client has access token and uuid from google$/) do
  steps %{
    Given the client has access token and uuid from facebook
  }
end

Given(/^client has registered in Rest API by google account$/) do
  steps %{
    Given client has registered in Rest API by facebook account and password "test_password"
  }
end

When(/^client send a POST request to \/user\/1\/register\/google with:$/) do |table|
  path = '//' + Settings.environments.api_domain + "/user/1/register/google"

  data = table.rows_hash
  user_id = data["user_id"].include?("INVALID") ? "" : @uuid
  access_token = data["access_token"].include?("INVALID") ? "" : @access_token

  if user_id.blank? || access_token.blank?
    Api::User::OauthController.any_instance.stub(get_oauth_data: nil)
  else
    Api::User::OauthController.any_instance.stub(get_oauth_data: @oauth_data)
  end

  signature = create_signature(@certificate.serial, @uuid, @access_token)
  signature = data["signature"].include?("INVALID") ? "" : signature

  post path, {
    user_id: @uuid,
    access_token: @access_token,
    password: data["password"],
    certificate_serial: @certificate.serial,
    signature: signature
  }
end
