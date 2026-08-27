# frozen_string_literal: true

class Components::Players::Portrait < Components::Base
  def initialize(player:, classes:, image_classes: "h-full w-full", fallback_classes: "w-full", **attributes)
    @player = player
    @classes = classes
    @image_classes = image_classes
    @fallback_classes = fallback_classes
    @attributes = attributes
  end

  def view_template
    div(**@attributes, class: container_classes) do
      if player_portrait?(@player)
        img(**player_portrait_attributes(@player, classes: @image_classes))
      else
        render Components::PlayerPortraitFallback.new(classes: @fallback_classes)
      end
    end
  end

  private

  def container_classes
    background = @player.position == "DST" ? "bg-slate-400/50" : "bg-slate-800"
    [ "flex items-end justify-center overflow-hidden", @classes, background ].join(" ")
  end
end
