class Api::V1::Auth::SessionsController < Api::V1::BaseController
  before_action :authenticate_user!, only: [:destroy]


  def create
    require_parameters([:auth, :password])
    sign_in(params[:auth], params[:password], { device_id: params[:device_id], device_os: params[:device_os] })
    render json: current_user
  end

  def destroy
    sign_out
  end

  # alias methods

end
