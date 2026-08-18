require "csv"

module Players
  class CsvImport
    REQUIRED_HEADERS = %w[name position pro_team].freeze

    Result = Data.define(:created, :updated)

    def initialize(file)
      @file = file
    end

    def call
      created = 0
      updated = 0

      ActiveRecord::Base.transaction do
        table.each do |row|
          player = find_player(row)
          player.new_record? ? created += 1 : updated += 1
          player.update!(attributes_from(row))
        end
      end

      Result.new(created:, updated:)
    end

    private

    attr_reader :file

    def table
      csv = CSV.read(file.path, headers: true, header_converters: :symbol)
      missing = REQUIRED_HEADERS.map(&:to_sym) - csv.headers
      raise ArgumentError, "Missing headers: #{missing.join(', ')}" if missing.any?

      csv
    end

    def find_player(row)
      return Player.find_or_initialize_by(espn_id: row[:espn_id]) if row[:espn_id].present?

      Player.find_or_initialize_by(name: row[:name], position: row[:position].to_s.upcase, pro_team: row[:pro_team].to_s.upcase)
    end

    def attributes_from(row)
      {
        espn_id: row[:espn_id].presence,
        name: row[:name],
        position: row[:position],
        pro_team: row[:pro_team],
        bye_week: row[:bye_week].presence,
        active: ActiveModel::Type::Boolean.new.cast(row[:active].presence || true)
      }
    end
  end
end
