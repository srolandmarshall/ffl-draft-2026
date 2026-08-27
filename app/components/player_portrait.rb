# frozen_string_literal: true

class Components::PlayerPortrait < Components::Base
  def initialize(player:, classes: "h-full w-full", **attributes)
    @player = player
    @classes = classes
    @attributes = attributes
  end

  def view_template
    if player_portrait?(@player)
      img(**player_portrait_attributes(@player, classes: @classes, **@attributes))
    else
      render Components::PlayerPortraitFallback.new(classes: "w-full")
    end
  end
end
