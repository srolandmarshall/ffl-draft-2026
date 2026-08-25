require "test_helper"

class Admin::RankingImportsControllerTest < ActionDispatch::IntegrationTest
  test "commissioner can choose a LeagueLogs profile" do
    sign_in_as users(:commissioner)

    get new_admin_ranking_import_path

    assert_response :success
    assert_select "h1", "Refresh rankings"
    assert_select "select[name='profile']"
    assert_select "a[href='https://leaguelogs.com']", "Powered by LeagueLogs API"
  end
end
