class Api::User::Token < Api::User
  
  def self.authenticate(payload = {})

    user = self.find_for_database_authentication(email: payload[:email])
    unless user and user.valid_password?(payload[:password])
      user.errors.add(:authenticate, {code: '001', description: 'Invalid email or password.'})
      return user
    end
    
    if ((Time.zone.now - user.created_at) / 1.day) > 3
      user.errors.add(:authenticate, {code: '002', description: 'client have to confirm email account before continuing.'})
      return user
    end

    user
  end

  def revoke_authentication_token key
    redis_token = Redis::Value.new(authentication_token_key(id.to_s, key))
    redis_token.delete
  end

end