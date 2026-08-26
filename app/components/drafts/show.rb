# frozen_string_literal: true

class Components::Drafts::Show < Components::Base
  def initialize(room:, current_user:, view: nil)
    @room = room
    @draft = room.draft
    @current_user = current_user
    @view = view
  end

  def view_template
    turbo_stream_from @draft
    content_for(:title, @draft.name)

    turbo_frame_tag("draft-#{@draft.public_id}-header") do
      render Components::Drafts::Header.new(@draft)
    end

    turbo_frame_tag("draft-#{@draft.public_id}-content") do
      @draft.complete? ? completed_draft : active_draft
    end
  end

  private

  def completed_draft
    render Components::Drafts::CompletedNavigation.new(draft: @draft, view: @view)
    if @view == "my_team"
      turbo_frame_tag("draft-#{@draft.public_id}-team-roster") { render team_roster }
    elsif @view == "facts"
      render facts
    else
      turbo_frame_tag("draft-#{@draft.public_id}-board") { render board }
    end
  end

  def active_draft
    turbo_frame_tag("draft-#{@draft.public_id}-room") do
      render Components::Drafts::Room.new(room: @room, current_user: @current_user, view: @view)
    end
  end

  def board
    Components::Drafts::Board.new(
      draft: @draft,
      picks: @room.picks,
      pick_elapsed_seconds: @room.pick_elapsed_seconds,
      selected_team: @room.selected_team
    )
  end

  def team_roster
    Components::Drafts::TeamRoster.new(
      draft: @draft,
      team: @room.roster_team,
      picks: @room.picks,
      commissioner: @current_user.commissioner?,
      preferred_team: @room.selected_team
    )
  end

  def facts
    generated_facts = ::Drafts::FactGenerator.new(
      draft: @draft,
      picks: @room.picks,
      pick_elapsed_seconds: @room.pick_elapsed_seconds
    ).call
    Components::Drafts::Facts.new(draft: @draft, facts: generated_facts)
  end
end
