# frozen_string_literal: true

class Components::FormErrors < Components::Base
  def initialize(record)
    @record = record
  end

  def view_template
    return unless @record.errors.any?

    div(class: "mb-5 rounded-xl border border-red-400/40 bg-red-400/10 p-4 text-sm text-red-200") do
      p(class: "font-semibold") { "#{@record.errors.count} #{@record.errors.count == 1 ? 'error' : 'errors'} prevented this from being saved:" }
      ul(class: "mt-2 list-disc pl-5") do
        @record.errors.full_messages.each { |message| li { message } }
      end
    end
  end
end
