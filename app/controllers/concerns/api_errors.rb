module ApiErrors

  def error(code)

    missing_param_code_modify = {}
    missing_param_code.each do |key, value|
      missing_param_code_modify[key] = "Missing Required Parameter: #{value}"
    end

    error = {
      "400.0"  => "Missing Required Header: X-Signature",
      "400.1"  => "Invalid signature",
      "400.3"  => "Invalid certificate_serial",
      "400.5"  => "Invalid app_id",
      "400.24" => "Device Not Found",
      "400.26" => "Invalid cloud_id",
      "400.28" => "Device Not Paired",
      "400.29" => "Invalid app_group_id",
      "400.32" => "Invalid template_id",
      "400.34" => "Template Params does not match",
      "400.35" => "Invalid template_params",
      "400.37" => "Missing Required Header: X-Timestamp",
      "400.38" => "Invalid timestamp",
      "400.44" => "Invalid content",
      "401.0"  => "Invalid access_token",
      "401.1"  => "Access Token Expired",
      "403.0"  => "User Is Not Device Owner",
      "403.1"  => "Device Already Paired",
      "404.2"  => "User Not Found",
      "404.3"  => "APP Not Found",
      "404.4"  => "Template Not Found",
      "500.0"  => "Failed To Queue The Job",
    }

    error.merge! missing_param_code_modify

    error[code]
  end

  def response_error(code)
    status = code.split('.')[0]
    render :json => { code: code, message: error(code) }, status: status
  end

  def missing_param_code
    {
      '400.2'  => 'certificate_serial',
      '400.4'  => 'app_id' ,
      '400.6'  => 'access_token',
      '400.22' => 'mac_address',
      '400.23' => 'serial_number',
      '400.25' => 'cloud_id' ,
      '400.29' => 'app_group_id',
      '400.31' => 'template_id',
      '400.33' => 'template_params',
      '400.36' => 'email' ,
      '400.39' => 'name',
      '400.40' => 'redirect_uri' ,
      '400.41' => 'create_table',
      '400.42' => 'description',
      '400.43' => 'content',
      '400.45' => 'identity',
      # '400.46' => 'title_en',
      # '400.47' => 'content_en',
      '400.46' => 'template_contents_attributes'
    }
  end

end
