module Mcp
  class DraftsController < BaseController
    before_action :set_draft

    def show
      render_json(Mcp::DraftData.new(@draft).summary)
    end

    def results
      render_json(Mcp::DraftData.new(@draft).results)
    end

    def players
      render_json(Drafts::PlayerListExport.new(@draft).as_json)
    end

    private

    def set_draft
      @draft = visible_draft
    end
  end
end
