class PairingSession #< ActiveRecord::Base

  # enum status: {start: 0, waiting: 1, done: 2, offline: 3, failure: 4}

  # belongs_to :user
  # belongs_to :device

  SESSION_REPIX = 'pairing:device'

  include Redis::Objects

  def initialize id = nil
    
  end

  self.redis_prefix = SESSION_REPIX
  hash_key :session
  # counter :index, key: SESSION_REPIX + ':index'

  def id
    @index.value
  end

  # def self.handling_status
  #   self.statuses.slice(:start, :waiting)
  # end

  # def self.handling_by_user(user_id)
  # 	self.where("user_id = ? AND status in (?) AND expire_at > NOW()", user_id, self.handling_status.map{|k,v| v}.join(','));
  # end

  # def self.handling()
  # 	self.where("status in (?) AND expire_at > NOW()", self.handling_status.map{|k,v| v});
  # end

  # def expire_in

  #   time_difference = Time.now.to_f - self.updated_at.to_f

  #   expire_time = 600
  #   expire_time -= time_difference if time_difference > 5
  #   return expire_time.to_i
  # end
end
