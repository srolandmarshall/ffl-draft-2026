class SessionsController < ApplicationController
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

    code = @user.issue_login_code!
    LoginCodeMailer.with(user: @user, code:).login_code.deliver_later
    session[:pending_user_id] = @user.id
    redirect_to verify_session_path, notice: "We sent a sign-in code to #{email}."
  end

  def verify
    redirect_to new_session_path unless pending_user
  end

  def confirm
    user = pending_user

    unless user
      redirect_to new_session_path, alert: "Request a new sign-in code."
      return
    end

    if user.verify_login_code!(params.expect(:code).to_s)
      session.delete(:pending_user_id)
      session[:user_id] = user.id
      redirect_to session.delete(:return_to) || root_path, notice: "Signed in as #{user.email}."
    else
      redirect_to verify_session_path, alert: "That code is invalid or has expired."
    end
  end

  def destroy
    reset_session
    redirect_to new_session_path, notice: "Signed out."
  end

  private

  def pending_user
    @pending_user ||= User.find_by(id: session[:pending_user_id])
  end
end
