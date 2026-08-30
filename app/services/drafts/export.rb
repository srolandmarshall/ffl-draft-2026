require "csv"
require "axlsx"

module Drafts
  class Export
    HEADERS = %w[team owner roster_slot player position pro_team espn_id round overall_pick].freeze

    def initialize(draft)
      @draft = draft
    end

    def to_csv
      CSV.generate(headers: true) do |csv|
        csv << HEADERS
        rows.each { |row| csv << HEADERS.map { |header| row.fetch(header) } }
      end
    end

    def to_xlsx
      package = Axlsx::Package.new
      add_sheet(package, name: "By Pick", rows: rows.sort_by { |row| row.fetch("overall_pick") })
      add_sheet(package, name: "By Team", rows: rows)
      package.to_stream.read
    end

    def as_json(*)
      {
        league: draft.league.name,
        season: draft.league.season,
        draft: draft.name,
        exported_at: Time.current.iso8601,
        teams: draft.draft_entries.map do |entry|
          {
            team: entry.team.name,
            owner: entry.team.owner_name,
            draft_position: entry.position,
            roster: roster_for(entry.team)
          }
        end
      }
    end

    private

    attr_reader :draft

    def rows
      draft.draft_entries.flat_map do |entry|
        roster_for(entry.team).map do |player|
          {
            "team" => entry.team.name,
            "owner" => entry.team.owner_name,
            "roster_slot" => player[:roster_slot],
            "player" => player[:name],
            "position" => player[:position],
            "pro_team" => player[:pro_team],
            "espn_id" => player[:espn_id],
            "round" => player[:round],
            "overall_pick" => player[:overall_pick]
          }
        end
      end
    end

    def roster_for(team)
      draft.picks.select { |pick| pick.team_id == team.id }.map.with_index(1) do |pick, slot|
        {
          roster_slot: slot,
          name: pick.player.name,
          position: pick.player.position,
          pro_team: pick.player.pro_team,
          espn_id: pick.player.espn_id,
          round: pick.round,
          overall_pick: pick.overall_number
        }
      end
    end

    def add_sheet(package, name:, rows:)
      package.workbook.add_worksheet(name:) do |sheet|
        sheet.add_row HEADERS.map(&:titleize)
        rows.each { |row| sheet.add_row HEADERS.map { |header| row.fetch(header) } }
        sheet.column_widths(*Array.new(HEADERS.size, 18))
      end
    end
  end
end
