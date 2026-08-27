# frozen_string_literal: true

class Components::Drafts::PlayerIdentity < Components::Base
  def initialize(player:, variant: :desktop)
    @player = player
    @variant = variant
  end

  def view_template
    div(class: outer_classes) do
      headshot
      div(class: "min-w-0") do
        if @variant == :desktop
          div(class: "flex items-center gap-2") do
            player_name
            rookie_badge
          end
          position_line
        else
          div(class: "flex flex-wrap items-center gap-2") do
            player_name
            position_badge
            team_logo unless @player.position == "DST"
            sr_only_team
            injury_badge
            rookie_badge
          end
        end
      end
    end
  end

  private

  def outer_classes
    @variant == :desktop ? "flex items-center gap-2.5" : "flex min-w-0 gap-2"
  end

  def headshot
    wrapper_size = @variant == :desktop ? "size-10" : "size-8"
    render Components::Players::Portrait.new(
      player: @player,
      classes: "#{wrapper_size} shrink-0 rounded-full border border-white/10"
    )
  end

  def player_name
    span(class: "break-words text-sm font-bold leading-tight text-white") { @player.name }
  end

  def rookie_badge
    return unless @player.rookie?

    classes = @variant == :desktop ? "inline-flex shrink-0 rounded-full bg-white/10 px-2 py-0.5 text-[.6rem] font-bold uppercase tracking-wide text-white" : "rounded-full bg-white/10 px-2 py-0.5 text-[.6rem] font-bold uppercase"
    span(class: classes) { "Rookie" }
  end

  def injury_badge
    return unless @player.injured?

    span(
      class: "inline-flex shrink-0 items-center gap-1 rounded-full border border-red-400/40 bg-red-400/10 px-1.5 py-0.5 text-[.6rem] font-bold uppercase tracking-wide text-red-200",
      title: injury_badge_title,
      aria: { label: injury_badge_title }
    ) do
      span(class: "text-red-400", aria: { hidden: true }) { "+" }
      span { @player.injury_status_abbreviation }
    end
  end

  def injury_badge_title
    updated = @player.injury_updated_at&.to_fs(:long)
    [ "ESPN injury status: #{@player.injury_status_label}", ("Updated #{updated}" if updated) ].compact.join(" · ")
  end

  def position_line
    div(class: "mt-1 flex items-center gap-2") do
      position_badge
      team_logo(size: "size-7") unless @player.position == "DST"
      sr_only_team
      injury_badge
    end
  end

  def position_badge
    dimensions = @variant == :desktop ? "h-7 min-w-7 px-2 text-xs" : "h-6 min-w-6 px-1.5 text-[.65rem]"
    span(class: "inline-flex items-center justify-center rounded border font-bold leading-none #{dimensions} #{position_badge_classes(@player.position)}") { @player.position }
  end

  def team_logo(size: @variant == :desktop ? "size-7" : "size-6")
    img(**nfl_team_logo_attributes(@player.pro_team, classes: "#{size} rounded bg-slate-400/50 p-0.5 object-contain"))
  end

  def sr_only_team
    span(class: "sr-only") { @player.pro_team }
  end
end
