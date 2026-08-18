module Admin
  class PlayerImportsController < BaseController
    def new; end

    def create
      result = Players::CsvImport.new(params.require(:file)).call
      redirect_to admin_players_path, notice: "Imported #{result.created} new and updated #{result.updated} players."
    rescue ArgumentError, CSV::MalformedCSVError, ActiveRecord::RecordInvalid => error
      flash.now[:alert] = error.message
      render :new, status: :unprocessable_entity
    end
  end
end
