# frozen_string_literal: true

class Components::Base < Phlex::HTML
  # Include any helpers you want to be available across all components
  include ApplicationHelper
  include Phlex::Rails::Helpers::ImageTag
  include Phlex::Rails::Helpers::ImagePath
  include Phlex::Rails::Helpers::ButtonTo
  include Phlex::Rails::Helpers::ContentFor
  include Phlex::Rails::Helpers::DOMID
  include Phlex::Rails::Helpers::FormAuthenticityToken
  include Phlex::Rails::Helpers::FormWith
  include Phlex::Rails::Helpers::NumberWithPrecision
  include Phlex::Rails::Helpers::Pluralize
  include Phlex::Rails::Helpers::Routes
  include Phlex::Rails::Helpers::TurboFrameTag
  include Phlex::Rails::Helpers::TurboStreamFrom
  include Phlex::Rails::Helpers::TimeAgoInWords
  include Phlex::Rails::Helpers::URLFor
end
