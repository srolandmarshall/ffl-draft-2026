# frozen_string_literal: true

class Components::RankingAttribution < Components::Base
  def initialize(sources:)
    @sources = Array(sources).compact.uniq
  end

  def view_template
    @sources.each_with_index do |source, index|
      plain " · " if index.positive?
      case source
      when DataSources::Rankings::LeagueLogs::SOURCE
        a(href: "https://leaguelogs.com", target: "_blank", rel: "noopener", class: "underline hover:text-slate-300") { "Powered by LeagueLogs API" }
      when DataSources::Rankings::FantasyFootballCalculator::SOURCE
        a(href: "https://fantasyfootballcalculator.com", target: "_blank", rel: "noopener", class: "underline hover:text-slate-300") { "ADP data provided by Fantasy Football Calculator" }
      end
    end
  end
end
