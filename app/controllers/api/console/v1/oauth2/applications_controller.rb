class Api::Console::V1::Oauth2::ApplicationsController < Api::Base
  include CheckParams
  include CheckSignature

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
    check_certificate_serial params
  end

  before_action do
    check_signature_urlsafe application_params, signature
  end

  before_action only: [:create] do
    check_params application_params, create_filter
  end

  before_action :find_client, only: [:show, :update, :destroy, :create_table]

  def index
    @apps = Doorkeeper::Application.all
    render json: { code: "0000", message: "OK", data: @apps }, status: 200
  end

  def show
    render json: { code: "0000", message: "OK", data: @app }, status: 200
  end

  def create
    @app = Doorkeeper::Application.new
    @app.name = params[:name]
    @app.scopes = params[:scopes] if params[:scopes]
    @app.redirect_uri = params[:redirect_uri]
    @app.logout_redirect_uri = params[:logout_redirect_uri]
    if @app.save
      if params[:create_table] == '1'
        begin
          create_dynamo_db(@app.uid)
        rescue => e
          return render :json => { code: e.code, message: e.message }, status: 400
        end
      end

      render json: { code: "0000", message: "OK", data: @app }, status: 200
    else
      render json: { message: @app.errors.full_messages.first }, status: 400
    end
  end

  def update
    if @app.update_attributes(update_params)
      render json: { code: "0000", message: "OK", data: @app }, status: 200
    else
      render json: { message: @app.errors.full_messages.first }, status: 400
    end
  end

  def destroy
    @app.destroy
    @app.access_grants.delete_all
    @app.access_tokens.delete_all
    # delete_dynamo_db(params[:client_id]) rescue nil
    delete_dynamo_db(@app.uid) rescue nil

    render json: { code: "0000", message: "OK" }, status: 200
  end

  def create_table
    # create_dynamo_db(params[:client_id])
    create_dynamo_db(@app.uid)
    render json: { code: '0000', message: 'OK' }, status: 200
  rescue => e
    render :json => { code: e.code, message: e.message }, status: 400
  end

  private

  def create_filter
    # ['name', 'redirect_uri']
    ['name']
  end

  def application_params
    params.permit(:certificate_serial, :id, :name, :redirect_uri, :scopes, :logout_redirect_uri, :create_table)
  end

  def update_params
    params.permit(:name, :redirect_uri, :scopes, :logout_redirect_uri)
  end

  def find_client
    @app = Doorkeeper::Application.find_by(id: params[:id])

    if @app.nil?
      return response_error('404.3')
    end
  end

  def create_dynamo_db(client_id)
    # ddb = AWS::DynamoDB::Client.new(api_version: '2012-08-10')
    ddb = Aws::DynamoDB::Client.new
    resp = ddb.create_table(dynamo_db_params(client_id))
  end

  def table_name(client_id)
    env = Settings.oss.env
    service = Settings.oss.service_name
    table_name = "#{env}-#{service}-#{client_id}"
  end

  def delete_dynamo_db(client_id)
    params = {
      table_name: table_name(client_id)
    }
    ddb = Aws::DynamoDB::Client.new
    # ddb = AWS::DynamoDB::Client.new(api_version: '2012-08-10')
    resp = ddb.delete_table(params)
  end

  def dynamo_db_params(client_id)

    params = {
      table_name: table_name(client_id),
      attribute_definitions: [
        {
          attribute_name: "domain_id",
          attribute_type: "S"
        },
        {
          attribute_name: "id",
          attribute_type: "S"
        },
        {
          attribute_name: "key",
          attribute_type: "S"
        }
      ],
      key_schema: [
        {
          attribute_name: "domain_id",
          key_type: "HASH"  #Partition key
        },
        {
          attribute_name: "id",
          key_type: "RANGE" #Sort key
        }
      ],
      provisioned_throughput: {
        read_capacity_units: 5,
        write_capacity_units: 5
      },
      global_secondary_indexes: [
        {
          index_name: "domain_id-key-index",
          key_schema: [
            {
              attribute_name: "domain_id",
              key_type: "HASH"  #Partition key
            },
            {
              attribute_name: "key",
              key_type: "RANGE" #Sort key
            }
          ],
          projection: {
            projection_type: "ALL"
          },
          provisioned_throughput: {
            read_capacity_units: 5,
            write_capacity_units: 5
          }
        }
      ]
    }
  end

end
