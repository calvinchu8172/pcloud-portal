class Api::Devices::V2::RegisterController < ApplicationController
  def api_permit
    params.permit(:mac_address, :serial_number, :model_class_name, :firmware_version, :signature, :module, :algo, :reset)
  end
end
