module TokenAuthentication
	extend ActiveSupport::Concern

  # after_action :build_response_headers

  def current_user
    return @current_resource
  end

	def user_signed_in?
		!current_user.nil?
	end

  def build_response_headers
		if user_signed_in?
	    uid, client, access_token = current_user.created_auth.nil? ?
	    [current_user.uid, request.headers['client'], request.headers['access-token']] :
	    [current_user.uid, current_user.created_auth.client, current_user.created_auth.access_token]
	    response.headers['uid']  = uid
	    response.headers['client']  = client
	    response.headers['access-token']  = access_token
			response.headers['resource-type'] = current_user.class.name.underscore
		end
  end

	def sign_out
		current_user.sign_out(request.headers["client"])
		@current_resource = nil
	end

	def sign_in(auth, password, metadata={})
		@current_resource = resource_class.sign_in!(auth, password, metadata)
	end

	def bypass_authenticate(resource)
		@current_resource = resource
		@current_resource.bypass_sign_in
	end

  def authenticate_user!
    authenticate_user
    raise CustomException::Authentication::Unauthorized unless user_signed_in?
  end

  def authenticate_user
    @current_resource = resource_class.authenticate_by_token(request.headers["uid"], request.headers["client"], request.headers["access-token"])
  end

	def resource_class
		r_class = request.headers["resource-type"]
    r_class ||= request.original_url.split("/")[5].singularize
		r_class.underscore.camelize.constantize
	end

end
