Recaptcha.configure do |config|
  # config.public_key = Settings.recaptcha.config.public_key
  # config.private_key = Settings.recaptcha.config.private_key
  config.site_key = Settings.recaptcha.config.public_key
  config.secret_key = Settings.recaptcha.config.private_key
end