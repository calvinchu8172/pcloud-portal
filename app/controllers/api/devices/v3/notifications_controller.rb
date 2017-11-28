class Api::Devices::V3::NotificationsController < Api::Base
  include CheckSignature 
  include CheckParams

  before_action do 
    check_header_timestamp timestamp
  end
  
  before_action do
    check_header_signature signature
  end
  
  before_action do
    check_timestamp_valid timestamp
  end
  
  before_action do
    check_certificate_serial valid_params
  end

  before_action do
    check_signature_urlsafe valid_params, signature
  end

  before_action do
    check_params valid_params, filter
  end

  def create 
    device = Device.includes(:product).find_by(mac_address: valid_params[:mac_address], serial_number: valid_params[:serial_number])
    return response_error("400.24") if device.blank?

    pairing = Pairing.find_by(device_id: device.id)
    return response_error("400.28") if pairing.blank?
    
    template = Template.find_by(identity: valid_params[:template_id])
    return response_error("400.32") if template.blank?

    begin 
      req_template_params = JSON.parse(valid_params[:template_params])
    rescue Exception => e
      logger.error("Parse template params failed: #{e.message}")
      return response_error("400.35")
    end

    en_template_content = template.en_template_content
    t_content_params = en_template_content.param_list

    if (t_content_params - req_template_params.keys).length > 0
      return response_error("400.34")
    end

    localizations = {}
    template.template_contents.each do |tc|
      unless(tc.title.blank?) 
        localizations[tc.locale.to_sym] = {
          title: tc.title
        }
        localizations[tc.locale.to_sym][:body] = tc.fit_params(req_template_params)
      end
    end

    request_id = request.headers.env["action_dispatch.request_id"]
    app_group_id = valid_params[:app_group_id]
    begin
      AwsService.send_message_to_queue(localizations, 'push_jobs', {
        "cloud_id" => { 
        :string_value => pairing.user.encoded_id, :data_type => 'String'
        },
        "title" => { 
          :string_value => en_template_content.title, :data_type => 'String'
        },
        "request_id" => { 
          :string_value => request_id, :data_type => 'String'
        },
        "app_group_id" => { 
          :string_value => app_group_id, :data_type => 'String'
        } 
      })
    rescue Exception => e
      logger.error("AWS SQS Send Message Failed: #{e.message}")
      return response_error("500.0")
    end
    
    product = device.product
    begin
      firehose = Aws::Firehose::Client.new
      data = {
        firmware_version: device.firmware_version,
        app_group_id: valid_params[:app_group_id],
        requested_at: Time.now.utc.strftime("%Y-%m-%d %H:%M:%S"),
        request_id: request_id,
        model_name: product.model_class_name,
        category: product.category.name,
        country: device.country
      }.to_json
      firehose.put_record({
        delivery_stream_name: Settings.environments.firehose.delivery_stream.name,
        record: {
          data: "#{data}\n"
        }
      })
    rescue Exception => e
      logger.error("AWS Firehose Put Record Failed: #{e.message}")
      return response_error("500.0")
    end
    
    render json: { request_id: request_id }, status: 200
  end

  private
  
    def valid_params
      params.permit(:certificate_serial, :app_group_id, :mac_address, :serial_number, :template_id, :template_params)
    end

    def filter
      ["app_group_id", "mac_address", "serial_number", "template_id", "template_params"]
    end


end