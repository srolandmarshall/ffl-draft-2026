# frozen_string_literal: true

class Components::Flash < Components::Base
  TYPE_CLASSES = {
    alert: "border-red-400/40 bg-red-400/10 text-red-200",
    notice: "border-lime-400/40 bg-lime-400/10 text-lime-100"
  }.freeze

  def initialize(messages)
    @messages = messages.to_h
  end

  def view_template
    @messages.each do |type, message|
      role = type.to_sym == :alert ? "alert" : "status"
      div(
        class: "mb-6 rounded-xl border px-4 py-3 text-sm #{TYPE_CLASSES.fetch(type.to_sym, TYPE_CLASSES[:notice])}",
        role:
      ) { message }
    end
  end
end
