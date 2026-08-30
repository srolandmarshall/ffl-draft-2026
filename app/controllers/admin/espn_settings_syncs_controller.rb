module Admin
  class EspnSettingsSyncsController < BaseController
    def create
      league = League.find(params[:league_id])
      raise DataSources::HttpError, "Add an ESPN league ID first." if league.espn_league_id.blank?

      result = DataSources::Espn::LeagueSync.new(league:, client: espn_client).call
      notice = "Synced ESPN rules, #{result.teams_matched} teams, #{result.player_scores_imported} player scores, #{result.standings_imported} standings, #{result.matchups_imported} matchups, and #{result.seasons_imported} draft seasons."
      notice += " Added #{result.teams_created} new teams after the current draft order." if result.teams_created.positive?
      notice += " Could not access #{result.seasons_skipped.to_sentence}." if result.seasons_skipped.any?
      redirect_to admin_league_path(league), notice:
    rescue DataSources::HttpError, ActiveRecord::RecordInvalid => error
      redirect_to admin_league_path(params[:league_id]), alert: error.message
    end
  end
end
