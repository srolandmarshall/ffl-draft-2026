# frozen_string_literal: true

class DraftRoom
  attr_reader :draft, :selected_team, :picks, :available_players, :available_teams,
    :player_filters, :roster_team, :pick_elapsed_seconds, :current_pick_elapsed_seconds

  def initialize(draft:, selected_team:, picks:, pick_elapsed_seconds:, current_pick_elapsed_seconds:,
    available_players: [], available_teams: [], player_filters: {}, roster_team: nil)
    @draft = draft
    @selected_team = selected_team
    @picks = picks
    @pick_elapsed_seconds = pick_elapsed_seconds
    @current_pick_elapsed_seconds = current_pick_elapsed_seconds
    @available_players = available_players
    @available_teams = available_teams
    @player_filters = player_filters
    @roster_team = roster_team
  end

  def picks_until_selected_team
    draft.picks_until_team(selected_team)
  end

  def can_make_pick?(user)
    draft.live? && (user.commissioner? || selected_team == draft.current_team)
  end
end
