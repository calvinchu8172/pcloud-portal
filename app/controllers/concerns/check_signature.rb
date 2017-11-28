module CheckSignature
  include ApiErrors

  def timestamp
    request.headers["X-Timestamp"]
  end

  def check_header_timestamp(timestamp)
     if timestamp.nil?
      return response_error("400.37")
    end
  end

  def check_timestamp_valid(timestamp)
    if Time.now.to_i - timestamp.to_i > 300
      return response_error("400.38")
    end
  end

  def signature
    request.headers["X-Signature"]
  end

  def check_header_signature(signature)
    if signature.nil?
      return response_error("400.0")
    end
  end

  def check_signature(params, signature)
    params = sort_params(params)
    key = params.values.join("")
    certificate_serial = params["certificate_serial"]
    unless validate_signature(signature, key, certificate_serial)
      return response_error("400.1")
    end
  end

  def check_signature_urlsafe(params, signature)
    params.merge!( {'X-Timestamp' => timestamp} )
    params = sort_params(params)
    key = params.values.join("")
    certificate_serial = params["certificate_serial"]
    unless validate_signature_urlsafe(signature, key, certificate_serial)
      return response_error("400.1")
    end
  end


  def sort_params(params)
    params = params.sort{ |a,z| a<=>z }.to_h
  end

  def validate_signature(signature, key, serial)
    sha224 = OpenSSL::Digest::SHA224.new
    begin
      result = Api::Certificate.find_public_by_serial(serial).verify(sha224, Base64.decode64(signature), key)
      return result
    rescue
      return false
    end
  end

  def validate_signature_urlsafe(signature, key, serial)
    sha224 = OpenSSL::Digest::SHA224.new
    begin
      result = Api::Certificate.find_public_by_serial(serial).verify(sha224, Base64.urlsafe_decode64(signature), key)
      return result
    rescue
      return false
    end
  end

end
