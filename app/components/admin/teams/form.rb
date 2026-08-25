# frozen_string_literal: true

class Components::Admin::Teams::Form < Components::Base
  def initialize(league:, team:)
    @league = league
    @team = team
  end

  def view_template
    render Components::FormErrors.new(@team)
    form_with(model: [ :admin, @league, @team ], class: "space-y-5") do |form|
      field(form, :name, autofocus: true)
      field(form, :owner_name)
      field(form, :abbreviation, label: "Abbreviation (2–5 letters)", maxlength: 5)
      div do
        form.label(:emails, "Team emails", class: label_classes)
        form.text_area(:emails, value: @team.emails.join("\n"), rows: 3, class: input_classes, placeholder: "owner@example.com\nco-owner@example.com")
        p(class: "mt-2 text-xs text-slate-500") { "One or more email addresses, separated by commas, spaces, or new lines." }
      end
      form.submit(class: "cursor-pointer rounded-lg bg-lime-400 px-5 py-2.5 font-semibold text-slate-950")
    end
  end

  private

  def field(form, attribute, label: nil, **options)
    div do
      form.label(attribute, label, class: label_classes)
      form.text_field(attribute, **options, class: input_classes)
    end
  end

  def label_classes = "mb-2 block text-sm font-bold"
  def input_classes = "w-full rounded-lg border border-white/15 bg-slate-950 px-3 py-2.5"
end
