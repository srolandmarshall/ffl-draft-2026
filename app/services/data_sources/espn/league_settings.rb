module DataSources
  module Espn
    class LeagueSettings
      Rule = Data.define(:label, :value)
      LINEUP_SLOTS = {
        qb_slots: [ "0" ],
        rb_slots: [ "2" ],
        wr_slots: [ "4" ],
        te_slots: [ "6" ],
        flex_slots: %w[3 5 7 23],
        dst_slots: [ "16" ],
        k_slots: [ "17" ],
        bench_slots: [ "20" ]
      }.freeze
      RECEPTION_STAT_ID = 53
      SUPPORTED_PPR = [ 0, 0.5, 1 ].freeze
      SCORING_LABELS = {
        3 => "Passing yards", 4 => "Passing touchdowns", 15 => "40+ yard passing touchdown bonus",
        16 => "50+ yard passing touchdown bonus", 17 => "300–399 yard passing game",
        18 => "400+ yard passing game", 19 => "Passing two-point conversion",
        20 => "Interceptions thrown", 24 => "Rushing yards", 25 => "Rushing touchdowns",
        26 => "Rushing two-point conversion", 35 => "40+ yard rushing touchdown bonus",
        36 => "50+ yard rushing touchdown bonus", 37 => "100–199 yard rushing game",
        38 => "200+ yard rushing game", 42 => "Receiving yards", 43 => "Receiving touchdowns",
        44 => "Receiving two-point conversion", 45 => "40+ yard receiving touchdown bonus",
        46 => "50+ yard receiving touchdown bonus", 53 => "Reception",
        56 => "100–199 yard receiving game", 57 => "200+ yard receiving game",
        63 => "Fumble recovered for touchdown", 72 => "Fumbles lost",
        77 => "Field goal made (40–49 yards)", 80 => "Field goal made (0–39 yards)",
        85 => "Field goal missed", 86 => "Extra point made", 88 => "Extra point missed",
        89 => "Defense: 0 points allowed", 90 => "Defense: 1–6 points allowed",
        91 => "Defense: 7–13 points allowed", 92 => "Defense: 14–17 points allowed",
        93 => "Blocked kick returned for touchdown", 94 => "Defensive return touchdown",
        95 => "Defensive interception", 96 => "Fumble recovery", 97 => "Blocked kick",
        98 => "Safety", 99 => "Sack", 101 => "Kickoff return touchdown",
        102 => "Punt return touchdown", 103 => "Interception return touchdown",
        104 => "Fumble return touchdown", 121 => "Defense: 18–21 points allowed",
        122 => "Defense: 22–27 points allowed", 123 => "Defense: 28–34 points allowed",
        124 => "Defense: 35–45 points allowed", 125 => "Defense: 46+ points allowed",
        128 => "Defense: under 100 yards allowed", 129 => "Defense: 100–199 yards allowed",
        130 => "Defense: 200–299 yards allowed", 131 => "Defense: 300–349 yards allowed",
        132 => "Defense: 350–399 yards allowed", 133 => "Defense: 400–449 yards allowed",
        134 => "Defense: 450–499 yards allowed", 135 => "Defense: 500–549 yards allowed",
        136 => "Defense: 550+ yards allowed", 198 => "Field goal made (50–59 yards)",
        201 => "Field goal made (60+ yards)", 206 => "Two-point return", 209 => "One-point safety"
      }.freeze
      SETTING_SUMMARIES = {
        "acquisitionSettings" => {
          "acquisitionBudget" => "FAAB budget", "acquisitionLimit" => "Season acquisition limit",
          "waiverHours" => "Waiver period (hours)", "waiverSystemType" => "Waiver system"
        },
        "tradeSettings" => {
          "max" => "Season trade limit", "revisionHours" => "Trade review (hours)",
          "vetoVotesRequired" => "Veto votes required"
        },
        "scheduleSettings" => {
          "matchupPeriodCount" => "Regular-season matchups", "playoffTeamCount" => "Playoff teams",
          "playoffSeedingRule" => "Playoff seeding"
        }
      }.freeze

      def self.from_payload(payload)
        new(payload.fetch("settings"))
      rescue KeyError => error
        raise HttpError, "ESPN settings response is missing #{error.key}"
      end

      def self.from_settings(settings)
        new(settings)
      end

      def initialize(raw_settings)
        @raw_settings = raw_settings.deep_dup.freeze
      end

      def draft_defaults
        defaults = roster_defaults.merge(ppr:)
        defaults[:draft_type] = :snake if snake_draft?
        defaults
      rescue KeyError => error
        raise HttpError, "ESPN settings response is missing #{error.key}"
      end

      def league_name
        raw_settings["name"]
      end

      def team_count
        raw_settings["size"].to_i
      end

      def raw_snapshot
        raw_settings.deep_dup
      end

      def lineup_rules
        slots = raw_settings.fetch("rosterSettings", {}).fetch("lineupSlotCounts", {})
        {
          "QB" => slots["0"].to_i, "RB" => slots["2"].to_i, "WR" => slots["4"].to_i,
          "TE" => slots["6"].to_i, "FLEX" => %w[3 5 23].sum { |id| slots[id].to_i },
          "OP" => slots["7"].to_i, "K" => slots["17"].to_i, "DST" => slots["16"].to_i,
          "Bench" => slots["20"].to_i, "IR" => slots["21"].to_i
        }.select { |_, count| count.positive? }
      end

      def scoring_rules
        raw_settings.fetch("scoringSettings", {}).fetch("scoringItems", []).filter_map do |item|
          stat_id = item["statId"].to_i
          value = item.fetch("pointsOverrides", {})["16"] || item["points"] || 0
          value = value.to_f
          Rule.new(label: SCORING_LABELS.fetch(stat_id, "ESPN stat ##{stat_id}"), value:) unless value.zero?
        end.sort_by(&:label)
      end

      def league_rules
        SETTING_SUMMARIES.flat_map do |section, fields|
          values = raw_settings.fetch(section, {})
          fields.filter_map do |key, label|
            value = values[key]
            Rule.new(label:, value:) if values.key?(key) && value.present? && !unlimited_limit?(key, value)
          end
        end
      end

      private

      attr_reader :raw_settings

      def unlimited_limit?(key, value)
        key.in?(%w[acquisitionLimit max]) && value.to_i == -1
      end

      def roster_defaults
        slots = raw_settings.fetch("rosterSettings").fetch("lineupSlotCounts")
        LINEUP_SLOTS.to_h do |attribute, slot_ids|
          [ attribute, slot_ids.sum { |slot_id| slots[slot_id].to_i } ]
        end
      end

      def ppr
        receptions = raw_settings.fetch("scoringSettings").fetch("scoringItems").find do |item|
          item["statId"].to_i == RECEPTION_STAT_ID
        end
        value = receptions ? receptions.fetch("pointsOverrides", {})["16"] || receptions["points"] : 0
        value = value.to_f
        raise HttpError, "ESPN uses unsupported #{value} PPR scoring" unless value.in?(SUPPORTED_PPR)

        value
      end

      def snake_draft?
        espn_type = raw_settings.fetch("draftSettings", {})["type"]
        [ 1, "SNAKE" ].include?(espn_type)
      end
    end
  end
end
