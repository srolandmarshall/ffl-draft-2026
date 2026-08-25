module DataSources
  module Rankings
    class Import
      Result = Data.define(:source, :updated, :unmatched, :meta, :attribution)

      def initialize(strategy:, imported_at: Time.current)
        @strategy = strategy
        @imported_at = imported_at
      end

      def call
        snapshot = strategy.call
        updated = 0
        unmatched = 0

        Player.transaction do
          clear_rankings(snapshot.positions)
          snapshot.entries.each do |entry|
            player = find_player(entry)
            if player
              player.update!(ranking_attributes(entry, snapshot.source))
              updated += 1
            else
              unmatched += 1
            end
          end
        end

        Result.new(source: snapshot.source, updated:, unmatched:, meta: snapshot.meta, attribution: snapshot.attribution)
      end

      private

      attr_reader :strategy, :imported_at

      def clear_rankings(positions)
        Player.where(position: positions).update_all(ranking: nil, ranking_source: nil, position_rank: nil, ranking_value: nil, ranking_updated_at: nil)
      end

      def find_player(entry)
        players_by_espn_id[entry.espn_id] || players_by_identity[identity(entry)] || unique_name_match(entry)
      end

      def unique_name_match(entry)
        matches = players_by_name.fetch([ normalize_name(entry.name), entry.position ], [])
        matches.first if matches.one?
      end

      def identity(entry)
        [ normalize_name(entry.name), entry.position, entry.pro_team ]
      end

      def normalize_name(name)
        ActiveSupport::Inflector.transliterate(name.to_s).downcase.gsub(/\b(jr|sr|ii|iii|iv)\b/, "").gsub(/[^a-z0-9]/, "")
      end

      def players
        @players ||= Player.all.to_a
      end

      def players_by_espn_id
        @players_by_espn_id ||= players.filter_map { |player| [ player.espn_id, player ] if player.espn_id }.to_h
      end

      def players_by_identity
        @players_by_identity ||= players.index_by { |player| [ normalize_name(player.name), player.position, player.pro_team ] }
      end

      def players_by_name
        @players_by_name ||= players.group_by { |player| [ normalize_name(player.name), player.position ] }
      end

      def ranking_attributes(entry, source)
        {
          ranking: entry.ranking,
          ranking_source: source,
          position_rank: entry.position_rank,
          ranking_value: entry.value,
          ranking_updated_at: imported_at
        }
      end
    end
  end
end
