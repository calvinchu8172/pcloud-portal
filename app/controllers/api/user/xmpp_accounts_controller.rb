class Api::User::XmppAccountsController < Api::Base
  before_filter :authenticate_user_by_token!, only: :update
  def update

    account = Api::User::XmppAccount.new(current_token_user.attributes.merge(update_params))
    account.valid?
    return render json: Api::User::INVALID_SIGNATURE_ERROR, :status => 400 unless account.errors[:signature].blank?
    account.uuid =  update_params[:uuid]
    xmpp_info = account.apply_for_xmpp_account
    #xmpp_info = current_token_user.apply_for_xmpp_account
    render :json =>  xmpp_info
  end

  private
    def update_params
      params.permit(:certificate_serial, :signature, :authentication_token, :cloud_id, :uuid)
    end
end
