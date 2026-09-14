class SessionsController < ApplicationController
  skip_forgery_protection only: %i[oauth_register oauth_token]

  def new
    redirect_to root_path if signed_in?
  end

  def create
    email = params.expect(:email).to_s.strip.downcase
    @user = User.find_by_any_email(email)

    unless @user&.allowed_to_sign_in?
      redirect_to new_session_path, alert: "That email is not assigned to a team."
      return
    end

    unless @user.login_code_request_allowed?
      redirect_to verify_session_path, alert: "Please wait a minute before requesting another code."
      return
    end

    session[:pending_user_id] = @user.id
    session[:pending_email] = email
    send_login_code_to(@user, email:)
    redirect_to verify_session_path, notice: "We sent a sign-in code to #{email}."
  end

  def verify
    @pending_user = pending_user
    return redirect_to(new_session_path) unless @pending_user

    @login_code_sent_at = @pending_user.login_code_sent_at
  end

  def resend_login_code
    user = pending_user
    return redirect_to(new_session_path, alert: "Request a new sign-in code.") unless user&.allowed_to_sign_in?

    unless user.login_code_request_allowed?
      redirect_to verify_session_path, alert: "Please wait a minute before requesting another code."
      return
    end

    send_login_code_to(user, email: pending_email || user.email)
    redirect_to verify_session_path, notice: "We sent you a new sign-in code."
  end

  def confirm
    user = pending_user

    unless user
      redirect_to new_session_path, alert: "Request a new sign-in code."
      return
    end

    if user.verify_login_code!(params.expect(:code).to_s)
      session.delete(:pending_user_id)
      session.delete(:pending_email)
      session[:user_id] = user.id
      redirect_to session.delete(:return_to) || root_path, notice: "Logged in as \"#{team_name_for(user)}\"."
    else
      redirect_to verify_session_path, alert: "That code is invalid or has expired."
    end
  end

  def destroy
    reset_session
    redirect_to new_session_path, notice: "Signed out."
  end

  def oauth_metadata
    render json: Mcp::Oauth.authorization_server_metadata(request.base_url)
  end

  def oauth_register
    render json: Mcp::Oauth.register_client(params.to_unsafe_h), status: :created
  rescue Mcp::Oauth::Error => error
    render_oauth_json_error(error)
  end

  def oauth_authorize
    authenticate_user!
    return if performed?

    @oauth_request = Mcp::Oauth.authorization_request(params.to_unsafe_h, request.base_url)
  rescue Mcp::Oauth::Error => error
    render plain: error.description, status: :bad_request
  end

  def oauth_approve
    authenticate_user!
    return if performed?

    location = Mcp::Oauth.complete_authorization(
      params.expect(:oauth_request),
      user: current_user,
      approved: params[:decision] == "approve"
    )
    redirect_to location, allow_other_host: true
  rescue Mcp::Oauth::Error => error
    render plain: error.description, status: :bad_request
  end

  def oauth_token
    render json: Mcp::Oauth.exchange_token(params.to_unsafe_h, request.base_url)
  rescue Mcp::Oauth::Error => error
    render_oauth_json_error(error)
  end

  private

  def render_oauth_json_error(error)
    render json: { error: error.code, error_description: error.description }, status: error.status
  end

  def pending_user
    @pending_user ||= User.find_by(id: session[:pending_user_id])
  end

  def pending_email
    session[:pending_email]
  end

  def send_login_code_to(user, email:)
    code = user.issue_login_code!
    LoginCodeMailer.with(code:, email:).login_code.deliver_later
  end

  def team_name_for(user)
    user.teams.joins(:league)
      .order(leagues: { season: :desc, id: :desc }, draft_order: :asc, id: :asc)
      .pick(:name) || "Commissioner"
  end
end
