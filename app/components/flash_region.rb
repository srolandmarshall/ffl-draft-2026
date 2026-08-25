# frozen_string_literal: true

class Components::FlashRegion < Components::Base
  def initialize(messages:)
    @messages = messages
  end

  def view_template
    div(id: "flash") { render Components::Flash.new(@messages) }
  end
end
