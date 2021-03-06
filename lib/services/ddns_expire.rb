module Services
  module DdnsExpire

    @rake_log = Rails.logger

    WARNING_TIME = 60.days.to_i - 1
    DELETE_TIME = 90.days.to_i - 1

    def self.notice
      current_time = Time.now.to_i

      warning_ddns = Ddns.where(status: [nil, 0]) # status = nil or 0, user of the ddns has not yet been noticed
      warning_device_account = Array.new
      warning_ddns.each do |ddns|
        warning_device_account << 'd' + ddns.device.mac_address.gsub(':', '-') + '-' + ddns.device.serial_number.gsub(/([^\w])/, '-')
      end

      xmpp_users = XmppLast.where([" ? - seconds > ? ", current_time, WARNING_TIME ]) # seconds = last_signout_at
      candidate_device_account = Array.new
      xmpp_users.each do |xmpp_user|
        if xmpp_user.offline?
          candidate_device_account << xmpp_user.username
        end
      end

      # 取交集 ( 1. xmpp 已經超過 60 天未上線 2. 從未被提醒過 )
      intersection_account = warning_device_account & candidate_device_account

      intersection_account_mac_address_and_serial_number = Array.new
      intersection_account.each do |username|
        username.slice!(0)
        username = username.split("-")
        intersection_account_mac_address_and_serial_number << username
      end

      @log_array = Array.new
      intersection_account_mac_address_and_serial_number.each do |i|
        device = Device.find_by(mac_address: i[0], serial_number: i[1])

        if device.present? && device.pairing.present? && device.pairing.first.user.present?

          device.ddns.status = 1
          device.ddns.ip_address = device.ddns.get_ip_addr
          device.ddns.save

          user = device.pairing.first.user
          xmpp_last_username = XmppLast.find_by_decive(device)
          expire_days = (current_time - xmpp_last_username.last_signout_at)/(24*60*60)

          DdnsMailer.notify_comment(user, device, xmpp_last_username).deliver_now

          info = {
            :user => user.email,
            :ddns => "#{ device.ddns.hostname }.#{device.ddns.domain.domain_name}",
            :expire_days => expire_days,
            :device => device.serial_number
          }
          @log_array << info
        end
      end
      @log_array
    end

    def self.delete
      current_time = Time.now.to_i

      warning_ddns = Ddns.where(status: [1])
      warning_device_account = Array.new
      warning_ddns.each do |ddns|
        warning_device_account << 'd' + ddns.device.mac_address.gsub(':', '-') + '-' + ddns.device.serial_number.gsub(/([^\w])/, '-')
      end

      xmpp_users = XmppLast.where([" ? - seconds > ? ", current_time, DELETE_TIME ])
      candidate_device_account = Array.new
      xmpp_users.each do |xmpp_user|
        if xmpp_user.offline?
          candidate_device_account << xmpp_user.username
        end
      end

      intersection_account = warning_device_account & candidate_device_account

      intersection_account_mac_address_and_serial_number = Array.new
      intersection_account.each do |username|
        username.slice!(0)
        username = username.split("-")
        intersection_account_mac_address_and_serial_number << username
      end

      @log_array = Array.new
      intersection_account_mac_address_and_serial_number.each do |i|
        device = Device.find_by(mac_address: i[0], serial_number: i[1])

        if device.present? && device.pairing.present? && device.pairing.first.user.present?

          Job.new.push_device_id(device.id.to_s)

          user = device.pairing.first.user
          xmpp_last_username = XmppLast.find_by_decive(device)
          expire_days = (current_time - xmpp_last_username.last_signout_at)/(24*60*60)

          info = {
            :user => user.email,
            :ddns => "#{ device.ddns.hostname }.#{device.ddns.domain.domain_name}",
            :expire_days => expire_days,
            :device => device.serial_number
          }
          @log_array << info
        end
      end
      @log_array
    end
  end
end

