Given(/^a user choose a device$/) do
  Capybara.session_name = "User1"
  @user = TestingHelper.create_and_signin
  @device = TestingHelper.create_device
end

Given(/^the user will redirect to pairing page$/) do
  visit "/discoverer/check/#{@device.encoded_id}"
end

Given(/^the user completely pairing a device$/) do
  steps %{
    When the user click "Confirm" button to start pairing
    And the user click the copy button of device within 10 minutes
    Then the user should see "Successfully paired." message on pairing page
    When the user click "DDNS Setting" button when finished pairing
  }
end

Given(/^another user2 in progress paired for the same device$/) do
  # switch to new bowser user2
  Capybara.session_name = "User2"
  @user2 = TestingHelper.create_and_signin
  visit "/discoverer/check/#{@device.encoded_id}"
  click_link "Confirm"
  # switch to user1
  Capybara.session_name = "User1"
end

# -------------------------------------------------------------------
# -------------------------- User behavior --------------------------
# -------------------------------------------------------------------

When(/^the user have other device$/) do
  @device2 = TestingHelper.create_device
  # Need add the key to mock the device was online
  # redis = Redis.new
  redis = Redis.new(:host => Settings.redis.web_host, :port => Settings.redis.port, :db => 0 )
  redis.HSET "s3:#{@device2.session['xmpp_account']}:#{Settings.xmpp.server}:#{Settings.xmpp.device_resource_id}".downcase, "1", "1"
end

When(/^complete the pairing process$/) do
  click_link "Confirm"
  @pairing_session = get_pairing_session(@device2)
  pairing_session_behavior(@pairing_session, "waiting", @device2)
  pairing_session_behavior(@pairing_session, "done", @device2)
  sleep 15
end

When(/^the user unpairing this device$/) do
  visit "/personal/index"
  expect(page).to have_link I18n.t("labels.unpairing"), href: "/unpairing/index/#{@device.encoded_id}"

  click_link(I18n.t("labels.unpairing"), :href => "/unpairing/index/#{@device.encoded_id}")
  expect(page).to have_content I18n.t("warnings.settings.unpairing.instruction")
  expect(page).to have_link I18n.t("labels.confirm")
  expect(page).to have_link I18n.t("labels.cancel")
  click_link "Confirm"

  current_url = URI.decode(page.current_path).chomp
  expect_url = URI.decode("/unpairing/success/" + @device.encoded_id).chomp
  expect(current_url).to eq(expect_url)

  # Need add the key to mock the device was online
  # redis = Redis.new
  redis = Redis.new(:host => Settings.redis.web_host, :port => Settings.redis.port, :db => 0 )
  redis.HSET "s3:#{@device.session['xmpp_account']}:#{Settings.xmpp.server}:#{Settings.xmpp.device_resource_id}".downcase, "1", "1"
end

When(/^the user visits Search Devices page$/) do
  visit "/discoverer/index"
end

When(/^the user click "(.*?)" button to start pairing$/) do |link|
  click_link link
  @pairing_session = get_pairing_session(@device)
end

When(/^the device was not connection$/) do
  pairing_session_behavior(@pairing_session, "offline", @device)
end

When(/^the user did not click on the copy button of device within (\d+) minutes$/) do |arg1|
  pairing_session_behavior(@pairing_session, "failure", @device)
end

When(/^the user click the copy button of device within (\d+) minutes$/) do |arg1|
  pairing_session_behavior(@pairing_session, "done", @device)
  sleep 15
end

When(/^the device was connection and pairing process is waiting$/) do
  steps %{
    When the user click "Confirm" button to start pairing
    Then the user should see the pairing information
  }
  pairing_session_behavior(@pairing_session, "waiting", @device)
end

When(/^the user click "(.*?)" button when finished pairing$/) do |link|
  @pairing = FactoryGirl.create(:pairing, user_id: @user.id, device_id: @device.id)
  wait_server_response
  within(:xpath, '//div[@class="bottom-content"]/div[@class="zyxel_btn_area ng-scope"]') do
    click_link link
  end
end

When(/^the user click "(.*?)" link to start pairing$/) do |link|
  # click_link "Pairing", href: "/discoverer/check/#{@device2.encoded_id}"
  # 因為Pairing按鈕被改成圖，所以用xpath去找連結
  find(:xpath, "//table/tbody/tr/td/a").click
end

When(/^the device doesn't have "(.*?)" module$/) do |device_module|
  redis = Redis.new(:host => Settings.redis.web_host, :port => Settings.redis.port, :db => 0 )
  key = "device:#{@device.id}:module_list"
  redis.srem(key, device_module)
end

# -------------------------------------------------------------------
# -------------------------- Expect result --------------------------
# -------------------------------------------------------------------

Then(/^the user should see another devices$/) do
  # expect(page).to have_link "Pairing", href: "/discoverer/check/#{@device2.encoded_id}"
  # 因為Pairing按鈕被改成圖，所以用xpath去找連結
  expect(page).to have_xpath "//table/tbody/tr/td/a"
end

Then(/^the user will see the error message about device is pairing$/) do
  expect(page).to have_content I18n.t("warnings.settings.pairing.in_pairing")
end

Then(/^the user should find the device after unpairing$/) do
  expect(page).to have_link I18n.t("labels.pairing"), href: "/discoverer/check/#{@device.encoded_id}"
end

Then(/^the user will redirect to Search Devices page$/) do
  expect(page.current_path).to eq "/discoverer/index"
end

Then(/^the user will see the confirm message about cancel Pairing flow$/) do
  expect(page).to have_content I18n.t("warnings.settings.pairing.cancel_instruction")
end

Then(/^the user should see "(.*?)" message on pairing page$/) do |msg|
  expect(page).to have_content(msg)
end

Then(/^the user should see "(.*?)" button on pairing page$/) do |button|
  expect(page).to have_content(button)
end

Then(/^the user should not see "(.*?)" button on pairing page$/) do |button|
  expect(page).to_not have_content(button)
end

Then(/^the user should see QR code on pairing page$/) do
  expect(page).to have_xpath('//img[@src="/assets/zdrive_qrcode.png"]')
  expect(page).to have_xpath('//img[@src="/assets/zcloud_qrcode.png"]')
end

Then(/^the user should see the pairing information$/) do
  expect(page).to have_content(I18n.t("warnings.settings.pairing.start.instruction"))
end

Then(/^the user will redirect to DDNS setup page$/) do
  current_url = URI.decode(page.current_path).chomp
  expect_url = URI.decode("/ddns/" + @device.encoded_id).chomp
  expect(current_url).to eq(expect_url)
end

Then(/^the user will redirect to root page$/) do
  expect(current_path).to eq("/")
end

Then(/^the user will go back to Pairing setup flow$/) do
  steps %{
    Then it should not do anything on Pairing page
  }
end

Then(/^it should not do anything on Pairing page$/) do
  expect(page).to have_content I18n.t("warnings.settings.pairing.start.instruction")
  expect(page).to have_content I18n.t("warnings.settings.pairing.start.instruction_2")
end

When(/^the device is not NAS$/) do
  @device.update(product_id: 39)
end

Then(/^the user should not see QR code on pairing page$/) do
  expect(page).not_to have_xpath('//img[@src="/assets/zdrive_qrcode.png"]')
  expect(page).not_to have_xpath('//img[@src="/assets/zcloud_qrcode.png"]')
end

def get_pairing_session(device)
  device.pairing_session.all
end

def pairing_session_behavior(pairing_session, status, device)
  pairing_session['status'] = status
  if (status == 'waiting')
    pairing_session['waiting_expire_at'] = (Time.now() + 10.minutes).to_i
  end
  device.pairing_session.update(pairing_session)
  wait_server_response
  pairing_session
end
