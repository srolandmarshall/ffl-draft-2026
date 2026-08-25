module DataSources
  module Rankings
    class Strategy
      Entry = Data.define(:source_id, :espn_id, :name, :position, :pro_team, :ranking, :position_rank, :value)
      Snapshot = Data.define(:source, :entries, :positions, :meta, :attribution)

      def call
        raise NotImplementedError, "Ranking strategies must implement #call"
      end
    end
  end
end
