class Api::V1::Auth::OmniauthController < Api::V1::BaseController

  def all
    params.require(:oauth_access_token)
    m_class = request.original_url.split('/')[-4].singularize.camelize.constantize
    @user = m_class.send(params[:provider] + "_sign_in", params[:oauth_access_token], omniauth_params)
    bypass_authenticate(@user)
    render json: @user
  end

  alias_method :facebook, :all
  alias_method :google_plus, :all

  private

    def omniauth_params
      params.permit(:name, :avatar, :email)
    end

end
