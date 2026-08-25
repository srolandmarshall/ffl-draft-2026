class AlignFantasyYearIxMunzLeagueHistory < ActiveRecord::Migration[8.1]
  MUNZ_OWNER_ID = "{997E1893-EDD5-42C5-B007-EFFAE08272F1}"

  class MigrationLeague < ActiveRecord::Base
    self.table_name = "leagues"
  end

  class MigrationTeam < ActiveRecord::Base
    self.table_name = "teams"
  end

  class MigrationFranchise < ActiveRecord::Base
    self.table_name = "espn_franchises"
  end

  class MigrationDraftPick < ActiveRecord::Base
    self.table_name = "espn_draft_picks"
  end

  def up
    league = MigrationLeague.find_by(name: "Fantasy Year IX")
    return unless league

    team = MigrationTeam.find_by(league_id: league.id, abbreviation: "MUNZ")
    munz = MigrationFranchise.find_by(league_id: league.id, key: "MUNZ")
    return unless team && munz

    munz.update!(
      team_id: team.id,
      name: "Diamond Dogs",
      aliases: [ "MUNZ", "M-U" ],
      owner_ids: [ MUNZ_OWNER_ID ]
    )

    MigrationFranchise
      .where(league_id: league.id, team_id: team.id)
      .where.not(id: munz.id)
      .update_all(team_id: nil)

    MigrationDraftPick
      .where(team_abbreviation: [ "MUNZ", "M-U" ])
      .where(espn_season_id: league_espn_season_ids(league.id))
      .update_all(espn_franchise_id: munz.id)
  end

  def down
    # The previous SETH-to-MUNZ association was erroneous historical data.
  end

  private

  def league_espn_season_ids(league_id)
    select_values(<<~SQL.squish)
      SELECT id FROM espn_seasons WHERE league_id = #{quote(league_id)}
    SQL
  end
end
