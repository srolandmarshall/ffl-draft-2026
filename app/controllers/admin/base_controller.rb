module Admin
  class BaseController < ApplicationController
    before_action :require_commissioner
    helper_method :espn_connected?

    private

    def require_commissioner
      authenticate_user!
      return if performed? || current_user&.commissioner?

      redirect_to root_path, alert: "Commissioner access is required."
    end

    def espn_client
      credentials = session[:espn_credentials]
      return DataSources::Espn::Client.new if credentials.blank?

      DataSources::Espn::Client.new(espn_s2: credentials["espn_s2"], swid: credentials["swid"])
    end

    def espn_connected?
      session.dig(:espn_credentials, "espn_s2").present? && session.dig(:espn_credentials, "swid").present?
    end
  end
end
