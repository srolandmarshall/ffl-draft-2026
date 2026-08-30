# frozen_string_literal: true

class Components::Admin::Drafts::Form < Components::Base
  SLOT_FIELDS = { qb_slots: "QB", rb_slots: "RB", wr_slots: "WR", te_slots: "TE", flex_slots: "FLEX", k_slots: "K", dst_slots: "DST", bench_slots: "Bench" }.freeze
  INPUT_CLASSES = "w-full rounded-lg border border-white/15 bg-slate-950 px-3 py-2.5".freeze

  def initialize(league:, draft:)
    @league = league
    @draft = draft
    @ordered_teams = draft.draft_entries.any? ? draft.draft_entries.map(&:team) : league.teams.active.in_draft_order.to_a
  end

  def view_template
    render Components::FormErrors.new(@draft)
    form_with(model: [ :admin, @league, @draft ], class: "space-y-8", data: { controller: "draft-setup", action: "draft-order:changed->draft-setup#update" }) do |form|
      basics(form)
      scoring(form)
      teams
      form.submit(class: "cursor-pointer rounded-lg bg-lime-400 px-5 py-2.5 font-semibold text-slate-950 hover:bg-lime-300")
    end
  end

  private

  def basics(form)
    section(class: "grid gap-5 rounded-xl border border-white/10 bg-slate-900 p-6 md:grid-cols-2") do
      div(class: "md:col-span-2") { section_header("Draft basics", "Set the room format and pace.") }
      builder_field(form, :name, autofocus: true, required: true)
      div do
        form.label(:scheduled_start_at, "Scheduled start (Eastern Time)", class: label_classes)
        render partial(
          "shared/date_picker/date_picker",
          id: "draft_scheduled_start_at",
          name: "draft[scheduled_start_at]",
          value: local_scheduled_start,
          placeholder: "Select date & time...",
          timepicker: true,
          date_format: "yyyy-MM-dd",
          time_format: "HH:mm",
          min_date: Date.current,
          minutes_step: 5,
          show_today_button: true,
          show_clear_button: true,
          input_class: INPUT_CLASSES,
          classes: "max-w-none"
        )
        p(class: "mt-1 text-xs text-slate-500") { "Optional. The draft starts automatically at this time; commissioners can still start it manually." }
      end
      div do
        form.label(:team_count, "Number of teams", class: label_classes)
        form.select(:team_count, (2..20).map { |count| [ pluralize(count, "team"), count ] }, {}, class: INPUT_CLASSES, data: { draft_setup_target: "count", action: "change->draft-setup#update" })
      end
      div do
        form.label(:draft_type, class: label_classes)
        form.select(:draft_type, Draft.draft_types.keys.map { |type| [ type.titleize, type ] }, {}, class: INPUT_CLASSES)
      end
    end
  end

  def scoring(form)
    section(class: "rounded-xl border border-white/10 bg-slate-900 p-6") do
      div(class: "mb-5") { section_header("Scoring and roster", "Rounds are calculated from the total roster slots.") }
      div(class: "grid gap-5 sm:grid-cols-2 lg:grid-cols-3") do
        div do
          form.label(:ppr, "Points per reception", class: label_classes)
          form.select(:ppr, [ [ "Standard · 0 PPR", 0 ], [ "Half PPR · 0.5", 0.5 ], [ "Full PPR · 1", 1 ] ], {}, class: INPUT_CLASSES)
        end
        SLOT_FIELDS.each { |attribute, label| builder_field(form, attribute, label:, type: :number, min: 0, max: 20, required: true) }
      end
    end
  end

  def teams
    section do
      div(class: "mb-4") { section_header("Teams and draft order", "Drag cards to set the order. Add multiple emails with commas or new lines.") }
      div(class: "space-y-4", data: { controller: "draft-order" }) do
        20.times { |index| team_slot(index, @ordered_teams[index]) }
      end
    end
  end

  def team_slot(index, team)
    fieldset(
      draggable: "true",
      class: "cursor-move rounded-xl border border-white/10 bg-slate-900 p-5 #{'hidden' if index >= @draft.team_count}",
      data: {
        draft_setup_target: "team",
        draft_order_target: "item",
        index:,
        action: "dragstart->draft-order#dragStart dragover->draft-order#dragOver drop->draft-order#drop dragend->draft-order#dragEnd"
      }
    ) do
      legend(class: "px-2 text-sm font-bold text-lime-400", data: { draft_order_target: "position" }) { "Pick #{index + 1}" }
      input(type: "hidden", name: slot_name(index, :id), value: team&.id)
      div(class: "grid gap-4 md:grid-cols-2 lg:grid-cols-4") do
        slot_field(index, :name, "Team name", team&.name || "Team #{index + 1}")
        slot_field(index, :owner_name, "Owner name", team&.owner_name || "Owner #{index + 1}")
        slot_field(index, :abbreviation, "Abbreviation", team&.abbreviation || Kernel.format("T%02d", index + 1), maxlength: 5)
        slot_field(index, :emails, "Email(s)", team&.emails&.join("\n"), textarea: true, placeholder: "owner@example.com")
      end
    end
  end

  def slot_field(index, attribute, label_text, value, textarea: false, **attributes)
    id = "draft_team_#{index}_#{attribute == :owner_name ? 'owner' : attribute}"
    div do
      label(for: id, class: "mb-2 block text-xs font-bold text-slate-300") { label_text }
      common = { name: slot_name(index, attribute), id:, class: INPUT_CLASSES, data: { required_for_team: true }, **attributes }
      textarea ? send(:textarea, **common, rows: 2) { value } : input(type: "text", value:, **common)
    end
  end

  def slot_name(index, attribute) = "draft[team_slots][#{index}][#{attribute}]"

  def builder_field(form, attribute, label: nil, type: :text, **options)
    div do
      form.label(attribute, label, class: label_classes)
      form.public_send("#{type}_field", attribute, **options, class: INPUT_CLASSES)
    end
  end

  def section_header(title, description)
    h2(class: "text-lg font-semibold") { title }
    p(class: "mt-1 text-sm text-slate-400") { description }
  end

  def label_classes = "mb-2 block text-sm font-bold"

  def local_scheduled_start
    @draft.scheduled_start_at&.in_time_zone&.strftime("%Y-%m-%d %H:%M")
  end
end
