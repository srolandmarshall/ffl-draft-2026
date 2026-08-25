# frozen_string_literal: true

class Components::Admin::ResourceFormPage < Components::Base
  def initialize(kicker:, title:, form:, width: "max-w-2xl", danger: nil)
    @kicker = kicker
    @title = title
    @form = form
    @width = width
    @danger = danger
  end

  def view_template
    div(class: "mx-auto #{@width}") do
      p(class: "text-sm font-bold text-lime-400") { @kicker }
      h1(class: "mb-7 text-2xl font-semibold") { @title }
      div(class: "rounded-lg border border-white/10 bg-slate-900 p-6") { render @form }
      render @danger if @danger
    end
  end
end
