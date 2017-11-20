class Device < ActiveRecord::Base
  include Redis::Objects
  include Guards::AttrEncryptor

  # relation
  belongs_to :product
  has_one :ddns
  has_many :pairing
  has_many :invitations

  # redis session
  hash_key :session
  hash_key :pairing_session
  set :module_list
  hash_key :module_version

  # constant variable
  DEFAULT_MODULE_LIST = [{name: 'ddns', ver: '1'}, {name: 'upnp', ver: '1'}]
  IP_ADDRESSES_KEY = 'device:ip_addresses:'

  before_save { mac_address.downcase! }

  def self.handling_status
    ['start', 'waiting']
  end

  def self.checkin args

    result = self.where( args.slice(:mac_address, :serial_number))
    if result.empty?

      product = Product.where(args.slice(:model_class_name))

      return nil if product.empty?

      instance = self.create(args.slice(:mac_address, :serial_number, :firmware_version).merge({product_id: product.first.id}))
      logger.info('create new device id:' + instance.id.to_s)
      return instance
    end

    instance = result.first
    unless args[:firmware_version] == instance.firmware_version
      logger.info('update device from fireware version' + args[:firmware_version] + ' from ' + instance.firmware_version)
      instance.update_attribute(:firmware_version, args[:firmware_version])
    end

    return instance
  end

  def is_nas?
    self.product.category.name == 'NAS'
  end

  def paired?
    !self.pairing.owner.empty?
  end

  def paired_with? user_id
    Pairing.owner.exists?(['device_id = ? and user_id = ?', self.id, user_id])
  end

  def update_ip_list new_ip

    unless self.session.get(:ip).nil?
      old_ip_list = Redis::HashKey.new( IP_ADDRESSES_KEY + self.session.get(:ip))
      old_ip_list.delete(self.id)
    end

    new_ip_list = Redis::HashKey.new( IP_ADDRESSES_KEY + new_ip)
    new_ip_list.store(self.id, 1)
  end

  # looking for the next setting after device pairing
  # step order by default module list
  def find_next_tutorial current_step = nil

    module_list = self.find_module_list
    skip_module = "upnp"
    module_list = module_list.reject { |m| m == skip_module }

    DEFAULT_MODULE_LIST.each do |step|
      return step[:name] if module_list.include? step[:name]
    end if current_step.blank?

    return 'finished' unless module_list.include?(current_step)

    current_index = DEFAULT_MODULE_LIST.find_index { |item| item[:name] == current_step }

    result = DEFAULT_MODULE_LIST.from(current_index + 1).each.map do |next_step|
      next unless module_list.include? next_step[:name]
      next_step unless next_step.blank?
    end.compact

    return 'finished' if result.blank?
    module_name = result.first[:name]
    if module_name == 'upnp'
      module_version = self.get_module_version(module_name)
      module_name = "mods/v#{module_version}/#{module_name}"
    end
    module_name
  end

  def has_module? module_name
    self.find_module_list.include?(module_name)
  end

  # ignore paring module at this step
  def find_module_list
    list = self.module_list.members.reject { |m| m == 'pairing'}
    list.blank? ? DEFAULT_MODULE_LIST.each.map { |m| m[:name] } : list
  end

  #it will be ignored if time difference in 5 seconds
  def pairing_session_expire_in

    waiting_second = Pairing::WAITING_PERIOD.to_i
    logger.debug('waiting_second:' + waiting_second.to_s);
    return 0 if !self.class.handling_status.include?(pairing_session.get('status'))

    time_difference = self.pairing_session.get('expire_at').to_i - Time.now().to_i
    time_difference = waiting_second if (waiting_second - time_difference) <= 5
    logger.debug('waiting_second:' + waiting_second.to_s + ', time_difference:' + time_difference.to_s)
    return time_difference
  end

  # 用來判斷該device 是否有連上線
  # 主要是透過連線到xmpp 的redis session server
  # 依照該規則產生的key 是否存在來判斷是否在線上
  # 如果跟redis session server 連線發生timeout，則判斷為沒在線上
  # @return [Boolean]
  def presence?

    if @presence.nil?
      session = self.session.all
      @presence = XmppPresence.new("s3:#{session['xmpp_account']}:#{Settings.xmpp.server}:#{Settings.xmpp.device_resource_id}".downcase)
    end
    @presence.exists?
  rescue TimeoutError => error
    logger.error('device presence error:' + error.backtrace.join("\n"))
    false
  end

  def get_module_version module_name
    module_version = self.module_version.get(module_name)
    module_version = 1 if self.find_module_list.include?(module_name) && module_version.blank?
    module_version
  end

  def get_xmpp_account
    self.session.hget("xmpp_account")+"@#{Settings.xmpp.server}/#{Settings.xmpp.device_resource_id}" unless self.session.hget("xmpp_account").blank?
  end

  def get_mac_address
    self.mac_address.scan(/.{2}/).join(":") unless self.mac_address.blank?
  end

  def dont_verify_serial_number?
    ['NSA325', 'NSA325 v2'].include?(self.product.model_class_name)
  end

  def self.search(mac_address, serial_number)
    devices = Device.where(mac_address: mac_address).includes(:product)
    return if devices.empty?
    devices.each do |device|
      return device if device.dont_verify_serial_number?
      return device if device.serial_number == serial_number
    end
    return
  end

  # defined conditions that device is available to pair
  def is_available_to_pair? current_user_id
    ( self.is_not_in_pairing_session? ||
      self.pairing_session_is_not_in_working_section? ||
      self.is_pairing_by_current_user?(current_user_id)
    ) && self.presence?
  end

  def is_not_in_pairing_session?
    self.pairing_session.size == 0
  end

  # pairing session not in handling
  def pairing_session_is_not_in_working_section?
    pairing_session = self.pairing_session.all
    !Device.handling_status.include?(pairing_session['status'])
  end

  def is_pairing_by_current_user? current_user_id
    pairing_session = self.pairing_session.all
    pairing_session['user_id'] == current_user_id.to_s
  end

  def ip_encode_hex
    IPAddr.new(current_ip_address).to_i.to_s(16).rjust(8, "0")
  end

  def ip_decode_hex
    IPAddr.new(self.ip_address.to_i(16), Socket::AF_INET).to_s
  end
end
