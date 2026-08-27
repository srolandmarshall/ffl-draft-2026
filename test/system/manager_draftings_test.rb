require "application_system_test_case"

class ManagerDraftingsTest < ApplicationSystemTestCase
  test "a manager confirms a player pick and sees the updated draft room" do
    draft = drafts(:one)
    player = players(:one)
    sign_in_in_browser(users(:member))

    visit draft_path(draft.public_id)
    all("[data-draft-player-id='#{player.id}'] [data-draft-pick-target='trigger']", visible: :all).first.click
    assert_selector "[aria-label='Confirm drafting #{player.name}']"

    all("[aria-label='Confirm drafting #{player.name}']", visible: :all).first.click

    assert_text "#{teams(:one).name} SELECTS #{player.name}"
    assert_equal 1, draft.reload.picks.count
    assert_no_selector "[data-draft-player-id='#{player.id}']"
  end
end
