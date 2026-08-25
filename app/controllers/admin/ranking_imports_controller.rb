class Admin::RankingImportsController < Admin::BaseController
  def new
    load_form
  end

  def create
    strategy = DataSources::Rankings::StrategyFactory.build(source:, league:, profile: params[:profile])
    result = DataSources::Rankings::Import.new(strategy:).call
    redirect_to admin_players_path, notice: "Rankings refreshed from #{result.source.humanize}: #{result.updated} players ranked and #{result.unmatched} source rows unmatched."
  rescue ArgumentError, DataSources::HttpError, ActiveRecord::RecordInvalid, KeyError => error
    load_form
    flash.now[:alert] = error.message
    render :new, status: :unprocessable_entity
  end

  private

  def load_form
    @source = source
    @profile = params[:profile].presence || DataSources::Rankings::LeagueLogs.default_profile(league)
  end

  def source
    ENV.fetch("PLAYER_RANKINGS_SOURCE", DataSources::Rankings::StrategyFactory::DEFAULT_SOURCE)
  end

  def league
    @league ||= League.order(season: :desc).first
  end
end
