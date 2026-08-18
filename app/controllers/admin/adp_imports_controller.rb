module Admin
  class AdpImportsController < BaseController
    def new
      league = League.order(season: :desc).first
      @defaults = { scoring_format: "ppr", teams: league&.teams&.count || 12, year: league&.season || Date.current.year }
    end

    def create
      payload = client.fetch_adp(scoring_format:, teams:, year:)
      result = DataSources::FantasyFootballCalculator::Import.new(payload).call
      redirect_to admin_players_path, notice: success_message(result)
    rescue ArgumentError, DataSources::HttpError, ActiveRecord::RecordInvalid, KeyError => error
      @defaults = { scoring_format:, teams:, year: }
      flash.now[:alert] = error.message
      render :new, status: :unprocessable_entity
    end

    private

    def client
      DataSources::FantasyFootballCalculator::Client.new
    end

    def scoring_format
      params.fetch(:scoring_format, "ppr")
    end

    def teams
      params.fetch(:teams, 12).to_i
    end

    def year
      params.fetch(:year, Date.current.year).to_i
    end

    def success_message(result)
      "ADP refreshed: #{result.created} players added and #{result.updated} updated from #{result.meta['total_drafts']} mock drafts."
    end
  end
end
