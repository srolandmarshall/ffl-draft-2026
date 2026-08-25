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
            injury_badge
          end
          position_line
        else
          div(class: "flex flex-wrap items-center gap-2") do
            player_name
            position_badge
            team_logo
            sr_only_team
            rookie_badge
            injury_badge
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
    size = @variant == :desktop ? 80 : 72
    wrapper_size = @variant == :desktop ? "size-10" : "size-9"
    fallback_margin = @variant == :desktop ? "mb-2" : "mb-1.5"
    div(class: "flex #{wrapper_size} shrink-0 items-end justify-center overflow-hidden rounded-full border border-white/10 bg-slate-800") do
      if @player.headshot.attached?
        img(src: url_for(player_headshot(@player, size:)), alt: "", loading: "lazy", class: "h-full w-full object-cover object-top")
      else
        span(class: "#{fallback_margin} text-[.6rem] font-black text-slate-500") { @player.position }
      end
    end
  end

  def player_name
    classes = @variant == :desktop ? "truncate text-sm font-bold text-white" : "text-sm font-bold leading-tight text-white"
    span(class: classes) { @player.name }
  end

  def rookie_badge
    return unless @player.rookie?

    classes = @variant == :desktop ? "inline-flex shrink-0 rounded-full bg-white/10 px-2 py-0.5 text-[.6rem] font-bold uppercase tracking-wide text-white" : "rounded-full bg-white/10 px-2 py-0.5 text-[.6rem] font-bold uppercase"
    span(class: classes) { "Rookie" }
  end

  def injury_badge
    return unless @player.injured?

    span(
      class: "shrink-0 rounded-full border border-red-400/40 bg-red-400/10 px-2 py-0.5 text-[.6rem] font-bold uppercase tracking-wide text-red-200",
      title: injury_badge_title
    ) { @player.injury_status_label }
  end

  def injury_badge_title
    updated = @player.injury_updated_at&.to_fs(:long)
    [ "ESPN injury status: #{@player.injury_status_label}", ("Updated #{updated}" if updated) ].compact.join(" · ")
  end

  def position_line
    div(class: "mt-1 flex items-center gap-2") do
      position_badge
      team_logo(size: "size-7")
      sr_only_team
    end
  end

  def position_badge
    dimensions = @variant == :desktop ? "h-7 min-w-7 px-2 text-xs" : "h-6 min-w-6 px-1.5 text-[.65rem]"
    span(class: "inline-flex items-center justify-center rounded border font-bold leading-none #{dimensions} #{position_badge_classes(@player.position)}") { @player.position }
  end

  def team_logo(size: @variant == :desktop ? "size-7" : "size-6")
    img(src: nfl_team_logo_url(@player.pro_team), alt: "", title: @player.pro_team, loading: "lazy", class: "#{size} rounded bg-slate-400/50 p-0.5 object-contain")
  end

  def sr_only_team
    span(class: "sr-only") { @player.pro_team }
  end
end
