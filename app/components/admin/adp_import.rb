# frozen_string_literal: true

class Components::Admin::AdpImport < Components::Base
  def initialize(defaults:)
    @defaults = defaults
  end

  def view_template
    div(class: "mx-auto max-w-2xl") do
      h1(class: "text-2xl font-semibold") { "Refresh ADP" }
      p(class: "mt-2 text-sm text-slate-400") { "This replaces the player board order with current mock-draft data. The source updates once daily, so hammering the button accomplishes nothing except disappointing a server." }
      import_form
      p(class: "mt-4 text-xs text-slate-500") do
        plain "ADP data provided by "
        a(href: "https://fantasyfootballcalculator.com", class: "underline", target: "_blank", rel: "noopener") { "Fantasy Football Calculator" }
        plain "."
      end
    end
  end

  private

  def import_form
    form_with(url: admin_adp_import_path, class: "mt-7 space-y-5 rounded-lg border border-white/10 bg-slate-900 p-6") do |form|
      div do
        form.label(:scoring_format, class: label_classes)
        form.select(:scoring_format, [ [ "PPR", "ppr" ], [ "Half PPR", "half-ppr" ], [ "Standard", "standard" ], [ "2-QB", "2-qb" ] ], { selected: @defaults[:scoring_format] }, class: input_classes)
      end
      div(class: "grid gap-5 sm:grid-cols-2") do
        number_field(form, :teams, min: 8, max: 14)
        number_field(form, :year, min: 2007, max: Date.current.year)
      end
      form.submit("Fetch ADP", class: "cursor-pointer rounded bg-lime-400 px-5 py-2.5 font-semibold text-slate-950")
    end
  end

  def number_field(form, attribute, **options)
    div do
      form.label(attribute, class: label_classes)
      form.number_field(attribute, value: @defaults[attribute], **options, class: input_classes)
    end
  end

  def label_classes = "mb-2 block text-sm font-semibold"
  def input_classes = "w-full rounded-lg border border-white/15 bg-slate-950 px-3 py-2.5"
end
