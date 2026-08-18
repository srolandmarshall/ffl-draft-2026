class SessionsController < ApplicationController
  def new
    redirect_to root_path if signed_in?
  end

  def create
    email = params.expect(:email).to_s.strip.downcase
    @user = User.find_by_any_email(email) || User.new(email:)
    @user.role = :commissioner if @user.new_record? && User.none?

    if @user.save
      session[:user_id] = @user.id
      redirect_to session.delete(:return_to) || root_path, notice: "Signed in as #{@user.email}."
    else
      flash.now[:alert] = @user.errors.full_messages.to_sentence
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    reset_session
    redirect_to new_session_path, notice: "Signed out."
  end
end
