# frozen_string_literal: true

# A player's portrait together with the box that frames it.
#
# Generated portraits are transparent WebP and headshots are cut off at the shoulders, so a
# placement is never just an `img`: it needs a fixed box that bottom-aligns the crop and
# carries a backdrop behind the alpha channel. Every caller framed that box itself, which is
# what let the silhouette fallback drift into a different shape than the headshot it stands
# in for. Only the box's size, corner, and border actually vary, so those are the parameter.
class Components::PlayerPortrait < Components::Base
  FRAME = "flex items-end justify-center overflow-hidden"

  def initialize(player:, frame: nil, frame_style: nil, image_classes: "h-full w-full", **image_attributes)
    @player = player
    @frame = frame
    @frame_style = frame_style
    @image_classes = image_classes
    @image_attributes = image_attributes
  end

  def view_template
    div(class: [ FRAME, backdrop, @frame ].compact.join(" "), style: @frame_style) do
      if player_portrait?(@player)
        img(**player_portrait_attributes(@player, classes: @image_classes, **@image_attributes))
      else
        render Components::PlayerPortraitFallback.new(classes: "w-full")
      end
    end
  end

  private

  # A defense's "portrait" is its NFL logo, which is dark enough to need the lighter plate
  # the logos get everywhere else; headshots sit on the neutral slate.
  def backdrop = @player.position == "DST" ? "bg-slate-400/50" : "bg-slate-800"
end
