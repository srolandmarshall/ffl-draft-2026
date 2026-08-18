module Admin
  class UsersController < BaseController
    def index
      @users = User.includes(:teams).order(:email)
    end

    def update
      user = User.find(params[:id])
      if user == current_user && params.dig(:user, :role) != "commissioner"
        redirect_to admin_users_path, alert: "You cannot remove your own commissioner access."
      elsif user.update(user_params)
        redirect_to admin_users_path, notice: "#{user.email} is now a #{user.role}."
      else
        redirect_to admin_users_path, alert: user.errors.full_messages.to_sentence
      end
    end

    private

    def user_params
      params.expect(user: :role)
    end
  end
end
