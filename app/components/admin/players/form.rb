# frozen_string_literal: true

class Components::Admin::Players::Form < Components::Base
  def initialize(player:)
    @player = player
  end

  def view_template
    render Components::FormErrors.new(@player)
    form_with(model: [ :admin, @player ], class: "space-y-5") do |form|
      field(form, :name, autofocus: true)
      div(class: "grid gap-5 sm:grid-cols-2") do
        div do
          form.label(:position, class: label_classes)
          form.select(:position, Player::POSITIONS, { prompt: "Select" }, class: input_classes)
        end
        field(form, :pro_team, label: "NFL team", maxlength: 4)
      end
      div(class: "grid gap-5 sm:grid-cols-2") do
        field(form, :espn_id, label: "ESPN player ID", type: :number)
        field(form, :bye_week, type: :number, min: 1, max: 18)
      end
      label(class: "flex items-center gap-3 text-sm font-bold") do
        form.checkbox(:active, class: "size-4 accent-lime-400")
        plain " Available to draft"
      end
      form.submit(class: submit_classes)
    end
  end

  private

  def field(form, attribute, label: nil, type: :text, **options)
    div do
      form.label(attribute, label, class: label_classes)
      form.public_send("#{type}_field", attribute, **options, class: input_classes)
    end
  end

  def label_classes = "mb-2 block text-sm font-bold"
  def input_classes = "w-full rounded-lg border border-white/15 bg-slate-950 px-3 py-2.5"
  def submit_classes = "cursor-pointer rounded-lg bg-lime-400 px-5 py-2.5 font-semibold text-slate-950"
end
