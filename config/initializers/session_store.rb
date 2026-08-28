# Keep authenticated browser sessions through normal browser restarts while limiting
# their lifetime if a device is lost or left signed in.
Rails.application.config.session_store :cookie_store,
  key: "_ffl_draft_session",
  expire_after: 7.days
