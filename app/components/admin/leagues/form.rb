# frozen_string_literal: true

class Components::Admin::Leagues::Form < Components::Base
  SLOT_FIELDS = { qb_slots: "QB", rb_slots: "RB", wr_slots: "WR", te_slots: "TE", flex_slots: "FLEX", k_slots: "K", dst_slots: "DST", bench_slots: "Bench" }.freeze

  def initialize(league:)
    @league = league
  end

  def view_template
    render Components::FormErrors.new(@league)
    form_with(model: [ :admin, @league ], class: "space-y-7") do |form|
      basics(form)
      defaults(form)
      roster(form)
      form.submit(class: submit_classes)
    end
  end

  private

  def basics(form)
    section(class: "space-y-5") do
      field(form, :name, autofocus: true, placeholder: "Sunday Gridiron League")
      field(form, :season, type: :number)
      div do
        field(form, :espn_league_id, label: "ESPN league ID", inputmode: "numeric", pattern: "[0-9]*", placeholder: "123456789")
        p(class: "mt-1 text-xs text-slate-500") { "Connects this season to its ESPN league for rules and future league data." }
      end
    end
  end

  def defaults(form)
    section(class: "border-t border-white/10 pt-6") do
      section_header("Draft defaults", "These settings apply when the next draft is created. Existing drafts are unchanged.")
      div(class: "mt-5 grid gap-5 sm:grid-cols-2") do
        select_field(form, :ppr, "Points per reception", [ [ "Standard · 0 PPR", 0 ], [ "Half PPR · 0.5", 0.5 ], [ "Full PPR · 1", 1 ] ])
        select_field(form, :draft_type, nil, League.draft_types.keys.map { |type| [ type.titleize, type ] })
      end
    end
  end

  def roster(form)
    section(class: "border-t border-white/10 pt-6") do
      section_header("Roster slots", "Roster size and draft rounds are calculated from these positions.")
      div(class: "mt-5 grid grid-cols-2 gap-4 sm:grid-cols-4") do
        SLOT_FIELDS.each { |attribute, label| field(form, attribute, label:, type: :number, min: 0, max: 20, required: true) }
      end
    end
  end

  def section_header(title, description)
    h2(class: "text-lg font-semibold") { title }
    p(class: "mt-1 text-xs text-slate-500") { description }
  end

  def field(form, attribute, label: nil, type: :text, **options)
    div do
      form.label(attribute, label, class: label_classes)
      form.public_send("#{type}_field", attribute, **options, class: input_classes)
    end
  end

  def select_field(form, attribute, label, choices)
    div do
      form.label(attribute, label, class: label_classes)
      form.select(attribute, choices, {}, class: input_classes)
    end
  end

  def label_classes = "mb-2 block text-sm font-bold"
  def input_classes = "w-full rounded-lg border border-white/15 bg-slate-950 px-3 py-2.5"
  def submit_classes = "cursor-pointer rounded-lg bg-lime-400 px-5 py-2.5 font-semibold text-slate-950 hover:bg-lime-300"
end
