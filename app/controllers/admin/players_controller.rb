module Admin
  class PlayersController < BaseController
    before_action :set_player, only: %i[edit update destroy]

    def index
      @players = Player.by_ranking.includes(headshot_attachment: :blob).limit(500)
    end

    def new
      @player = Player.new(active: true)
    end

    def create
      @player = Player.new(player_params)
      if @player.save
        redirect_to admin_players_path, notice: "Player created."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit; end

    def update
      if @player.update(player_params)
        redirect_to admin_players_path, notice: "Player updated."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @player.destroy!
      redirect_to admin_players_path, notice: "Player deleted."
    end

    private

    def set_player
      @player = Player.find(params[:id])
    end

    def player_params
      params.expect(player: %i[espn_id name position pro_team bye_week active])
    end
  end
end
