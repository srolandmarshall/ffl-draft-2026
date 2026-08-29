class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  helper_method :current_user, :signed_in?

  private

  def current_user
    @current_user ||= User.find_by(id: session[:user_id])
  end

  def signed_in?
    current_user.present?
  end

  def authenticate_user!
    return if signed_in?

    session[:return_to] = request.fullpath if request.get? || request.head?
    redirect_to new_session_path, alert: "Enter your email to continue."
  end

  def authenticate_user_or_bearer_token!
    return if signed_in?
    return authenticate_user! if request.format.html?
    return if (api_token = ApiToken.find_by_raw_token(bearer_token)) && set_api_token_user(api_token)

    head :unauthorized
  end

  def bearer_token
    request.headers["Authorization"].to_s.match(/\ABearer\s+(\S+)\z/i)&.captures&.first
  end

  def set_api_token_user(api_token)
    @current_user = api_token.user
    api_token.touch(:last_used_at)
    true
  end
end
