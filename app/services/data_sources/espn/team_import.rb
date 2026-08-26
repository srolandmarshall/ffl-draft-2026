module DataSources
  module Espn
    class TeamImport
      Result = Data.define(:matched, :created)

      def initialize(league:, teams:)
        @league = league
        @teams = teams
      end

      def call
        matched = 0
        created = 0

        teams.each do |identity|
          team = match(identity)
          release_reused_slot(identity, except: team)
          if team
            team.update!(espn_team_id: identity.id)
            matched += 1
          else
            team = league.teams.create!(
              espn_team_id: identity.id,
              name: identity.name,
              abbreviation: unique_abbreviation(identity.abbreviation),
              owner_name: identity.owner_names.join(" & ").presence || identity.name
            )
            created += 1
          end
          franchise = FranchiseResolver.new(league:).resolve(
            abbreviation: identity.abbreviation,
            name: identity.name,
            espn_team_id: identity.id,
            season: league.season,
            owner_ids: identity.owner_ids
          )
          franchise.update!(team:) unless franchise.team == team
        end

        Result.new(matched:, created:)
      end

      private

      attr_reader :league, :teams

      def match(identity)
        franchise = league.espn_franchises.to_a.find { |candidate| candidate.matches_alias?(identity.abbreviation) }
        franchise&.team ||
          league.teams.find_by("UPPER(abbreviation) = ?", identity.abbreviation.upcase) ||
          league.teams.find { |team| normalize(team.name) == normalize(identity.name) }
      end

      def release_reused_slot(identity, except:)
        scope = league.teams.where(espn_team_id: identity.id)
        scope = scope.where.not(id: except.id) if except
        scope.update_all(espn_team_id: nil)
      end

      def unique_abbreviation(abbreviation)
        base = abbreviation.to_s.upcase.gsub(/[^A-Z0-9]/, "").first(5).presence || "ESPN"
        return base unless league.teams.exists?(abbreviation: base)

        1.upto(99) do |suffix|
          candidate = "#{base.first(5 - suffix.to_s.length)}#{suffix}"
          return candidate unless league.teams.exists?(abbreviation: candidate)
        end

        raise DataSources::HttpError, "Could not generate a unique team abbreviation from \"#{abbreviation}\"; free up an abbreviation slot and retry."
      end

      def normalize(value)
        ActiveSupport::Inflector.transliterate(value.to_s).downcase.gsub(/[^a-z0-9]/, "")
      end
    end
  end
end
