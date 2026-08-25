# frozen_string_literal: true

class Components::Drafts::Touchdowns < Components::Base
  def initialize(stats:, variant: :desktop)
    @stats = stats
    @variant = variant
  end

  def view_template
    return span(class: "text-slate-600") { "—" } if @stats.empty? && @variant == :desktop
    return if @stats.empty?

    if @variant == :mobile
      div(class: "flex items-center gap-5 py-2 first:pt-0") do
        p(class: "mr-auto text-[.6rem] font-bold uppercase tracking-wider text-slate-400") { "Touchdowns" }
        stats_list("flex gap-5", "text-base")
      end
    else
      stats_list("flex justify-center gap-2", "")
    end
  end

  private

  def stats_list(list_class, value_size)
    dl(class: list_class) do
      @stats.each do |label, value|
        div(class: "flex flex-col text-center") do
          dt(class: "order-2 mt-1 text-[.55rem] font-bold uppercase tracking-wide text-slate-500") { label }
          dd(class: "order-1 #{value_size} font-black tabular-nums leading-none text-slate-100") { value }
        end
      end
    end
  end
end
