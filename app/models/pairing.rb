class Pairing < ActiveRecord::Base
  scope :owner, -> { where(ownership: 0) }

  include Guards::AttrEncryptor

  belongs_to :user
  belongs_to :device
end
