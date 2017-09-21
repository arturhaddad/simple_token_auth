class Api::V1::BaseController < ApplicationController
	protect_from_forgery with: :null_session

	include Pundit
	include ResourceLoader
	include TokenAuthentication

	after_action :build_response_headers
	# after_action :verify_authorized, except: :index
	# after_action :verify_policy_scoped, only: :index

	rescue_from ActiveRecord::RecordNotFound do |exception|
		render json: { errors: ["Resource not found."] }, status: :not_found
	end

	rescue_from ActionController::ParameterMissing do |exception|
		render json: { errors: ["Missing parameters: #{list_to_comma_string(exception.param)}"] }, status: :bad_request
	end

	rescue_from CustomException::Authentication::InvalidCredentials do |exception|
    render json: { errors: ["Invalid credentials"] }, status: :unauthorized
  end

	rescue_from CustomException::Authentication::Unauthorized do |exception|
    render json: { errors: ["Unauthorized"] }, status: :unauthorized
  end

	rescue_from Pundit::NotAuthorizedError do |exception|
		render json: { errors: ["Forbidden"] }, status: :forbidden
	end

	rescue_from ActiveRecord::RecordInvalid do |exception|
    errors = exception.to_s.split(', ')
    render json: { errors: errors }, status: :unprocessable_entity
  end

	def require_parameters(required_params=[])
		missing_params = Array.new
		required_params.map { |p| missing_params << p unless params.has_key? p }
		raise ActionController::ParameterMissing.new(missing_params) if missing_params.any?
	end
	
	def pundit_user
    current_user
	end

	private

		def list_to_comma_string(list)
			if list.is_a? Array
				s = ""
				list.each do |l|
					s+= " " + l.to_s + ","
				end
				s[0] = ""
				s[s.length() -1] = "."
				return s
			else
				list.to_s
			end
		end

end
