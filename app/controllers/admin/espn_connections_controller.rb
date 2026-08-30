module Admin
  class EspnConnectionsController < BaseController
    before_action :set_league

    def new; end

    def create
      espn_s2 = params.expect(:espn_s2).to_s.strip
      swid = params.expect(:swid).to_s.strip
      raise DataSources::HttpError, "Both ESPN cookies are required." if espn_s2.blank? || swid.blank?

      client = DataSources::Espn::Client.new(espn_s2:, swid:)
      result = DataSources::Espn::LeagueSync.new(league: @league, client:).call
      session[:espn_credentials] = { "espn_s2" => espn_s2, "swid" => swid }
      redirect_to admin_league_path(@league), notice: "Connected to ESPN and synced #{result.seasons_imported} draft seasons, #{result.standings_imported} standings, and #{result.matchups_imported} matchups."
    rescue DataSources::HttpError, ActiveRecord::RecordInvalid => error
      flash.now[:alert] = error.message
      render :new, status: :unprocessable_entity
    end

    def destroy
      session.delete(:espn_credentials)
      redirect_to admin_league_path(@league), notice: "ESPN account disconnected from this browser session."
    end

    private

    def set_league
      @league = League.find(params[:league_id])
      raise ActiveRecord::RecordNotFound if @league.espn_league_id.blank?
    end
  end
end
