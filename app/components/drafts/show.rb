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
    turbo_frame_tag("draft-#{@draft.public_id}-results") do
      render Components::Drafts::Results.new(
        draft: @draft,
        picks: @room.picks,
        pick_elapsed_seconds: @room.pick_elapsed_seconds,
        current_user: @current_user
      )
    end
    turbo_frame_tag("draft-#{@draft.public_id}-board") do
      render board
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
end
