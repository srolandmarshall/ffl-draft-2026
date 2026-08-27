# frozen_string_literal: true

# Stands in for a player photo that is missing, or whose portrait variant has not been
# generated yet. Every placement labels the position elsewhere in the same row, so a
# silhouette reads as "no photo" where a repeated position abbreviation read as broken.
class Components::PlayerPortraitFallback < Components::Base
  def initialize(classes: "h-full w-full")
    @classes = classes
  end

  def view_template
    svg(
      viewBox: "0 0 24 24",
      fill: "currentColor",
      aria: { hidden: "true" },
      class: "text-slate-600 #{@classes}"
    ) do |silhouette|
      silhouette.circle(cx: 12, cy: 9, r: 4.25)
      silhouette.path(d: "M12 15.25c-4.4 0-7.75 2.6-7.75 5.75V24h15.5v-3c0-3.15-3.35-5.75-7.75-5.75z")
    end
  end
end
