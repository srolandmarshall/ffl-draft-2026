# frozen_string_literal: true

class Components::Drafts::ProductionGroups < Components::Base
  def initialize(groups:, variant: :desktop)
    @groups = groups
    @variant = variant
  end

  def view_template
    return empty_state unless @groups.any?

    @variant == :mobile ? mobile_groups : desktop_groups
  end

  private

  def empty_state
    span(class: @variant == :mobile ? "text-xs text-slate-500" : "text-slate-500") { "No prior-season stats" }
  end

  def desktop_groups
    div(class: "grid grid-cols-2 gap-3") do
      @groups.each do |group|
        div(class: "border-l border-white/10 pl-3 first:border-l-0 first:pl-0 #{'col-span-2' if @groups.one?}") do
          p(class: "mb-1 text-[.55rem] font-bold uppercase tracking-wider text-slate-500") { group[:label] }
          stat_list(group[:stats], "gap-2.5", "")
        end
      end
    end
  end

  def mobile_groups
    div(class: "mt-2 divide-y divide-white/10") do
      @groups.each do |group|
        section(class: "py-2 first:pt-0") do
          h3(class: "mb-2 text-[.6rem] font-bold uppercase tracking-wider text-slate-400") { group[:label] }
          stat_list(group[:stats], "min-w-0 justify-between", "text-base")
        end
      end
    end
  end

  def stat_list(stats, gap, value_size)
    dl(class: "flex #{gap}") do
      stats.each do |label, value|
        div(class: "flex min-w-0 flex-col text-center") do
          dt(class: "order-2 mt-1 text-[.5rem] font-bold uppercase tracking-wide text-slate-500") { label }
          dd(class: "order-1 #{value_size} font-black tabular-nums leading-none text-slate-100") { value }
        end
      end
    end
  end
end
