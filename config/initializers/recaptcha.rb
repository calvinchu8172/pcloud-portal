Recaptcha.configure do |config|
  # config.public_key  = '6LelPvUSAAAAAHQP8AccRDnMO0ETmgmtY-okFr95'
  # config.private_key = '6LelPvUSAAAAAGdYfFVdxTPayPH1cQG5jIpoDqcj'
  config.public_key = Settings.recaptcha.config.public_key
  config.private_key = Settings.recaptcha.config.private_key
end