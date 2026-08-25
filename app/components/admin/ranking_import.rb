# frozen_string_literal: true

class Components::Admin::RankingImport < Components::Base
  def initialize(source:, profile:)
    @source = source
    @profile = profile
  end

  def view_template
    div(class: "mx-auto max-w-2xl") do
      h1(class: "text-2xl font-semibold") { "Refresh rankings" }
      p(class: "mt-2 text-sm text-slate-400") { description }
      import_form
      attribution
    end
  end

  private

  def description
    return "This replaces the player board order with the latest LeagueLogs market rankings." if league_logs?

    "This replaces the player board order using the configured rankings strategy."
  end

  def import_form
    form_with(url: admin_ranking_import_path, class: "mt-7 space-y-5 rounded-lg border border-white/10 bg-slate-900 p-6") do |form|
      if league_logs?
        form.label(:profile, "League profile", class: label_classes)
        form.select(:profile, profile_options, { selected: @profile }, class: input_classes)
      end
      form.submit("Fetch rankings", class: "cursor-pointer rounded bg-lime-400 px-5 py-2.5 font-semibold text-slate-950")
    end
  end

  def attribution
    p(class: "mt-4 text-xs text-slate-500") do
      render Components::RankingAttribution.new(sources: @source)
      plain ". Market values refresh every six hours." if league_logs?
    end
  end

  def profile_options
    DataSources::Rankings::LeagueLogs::PROFILES.map { |value, label| [ label, value ] }
  end

  def league_logs? = @source == DataSources::Rankings::LeagueLogs::SOURCE
  def label_classes = "mb-2 block text-sm font-semibold"
  def input_classes = "w-full rounded-lg border border-white/15 bg-slate-950 px-3 py-2.5"
end
