require "json"
require "axlsx"
require "prawn"
require "prawn/table"

module Drafts
  class PlayerListExport
    HEADERS = %w[name position pro_team bye_week ranking position_rank injury_status drafted roster_owner].freeze

    def initialize(draft, players: nil)
      @draft = draft
      @players = players || Player.active.by_ranking
    end

    def as_json(*)
      {
        league: {
          name: draft.league.name,
          season: draft.league.season
        },
        draft: {
          id: draft.public_id,
          name: draft.name,
          status: draft.status,
          picks_made: draft.picks.size,
          total_picks: draft.total_picks
        },
        exported_at: Time.current.iso8601,
        players: rows
      }
    end

    def to_json
      JSON.pretty_generate(as_json)
    end

    def to_xlsx
      package = Axlsx::Package.new
      package.workbook.add_worksheet(name: "Players") do |sheet|
        sheet.add_row HEADERS.map(&:titleize)
        rows.each { |row| sheet.add_row HEADERS.map { |header| row.fetch(header) } }
        sheet.column_widths(*Array.new(HEADERS.length, 18))
      end
      package.to_stream.read
    end

    def to_pdf
      Prawn::Document.new(page_layout: :landscape, margin: 28) do |pdf|
        pdf.text "#{draft.league.name} — #{draft.name}", size: 18, style: :bold
        pdf.text "Player list · #{draft.status.titleize} · #{draft.picks.size} of #{draft.total_picks} picks made", size: 9
        pdf.move_down 12
        pdf.table([ HEADERS.map(&:titleize) ] + rows.map { |row| HEADERS.map { |header| row.fetch(header).to_s } },
          header: true,
          width: pdf.bounds.width,
          cell_style: { size: 7, padding: 4 },
          row_colors: %w[F3F4F6 FFFFFF])
      end.render
    end

    private

    attr_reader :draft, :players

    def rows
      @rows ||= begin
        picks_by_player_id = draft.picks.includes(:team).index_by(&:player_id)
        players.map do |player|
          pick = picks_by_player_id[player.id]
          {
            "name" => player.name,
            "position" => player.position,
            "pro_team" => player.pro_team,
            "bye_week" => player.bye_week,
            "ranking" => player.ranking,
            "position_rank" => player.position_rank,
            "injury_status" => player.injury_status,
            "drafted" => pick.present?,
            "roster_owner" => pick&.team&.owner_name
          }
        end
      end
    end
  end
end
