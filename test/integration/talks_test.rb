require 'test_helper'

class TalksTest < ActionDispatch::IntegrationTest
  test '만들어요' do
    sign_in(users(:one))

    post talks_path(talk: { title: 'title' }, comment_body: 'body', issue_title: issues(:issue1).title)

    assert assigns(:talk).persisted?
    assigns(:talk).reload
    assert_equal 'title', assigns(:talk).title
    assert_equal users(:one), assigns(:talk).user
    assert_equal issues(:issue1).title, assigns(:talk).issue.title

    comment = assigns(:talk).comments.first
    assert comment.persisted?
    assert_equal 'body', comment.body
    assert_equal users(:one), assigns(:talk).user
  end

  test '고쳐요' do
    sign_in(users(:one))

    put talk_path(talks(:talk1), talk: { title: 'title x' }, issue_title: issues(:issue2).title)

    refute assigns(:talk).errors.any?
    assigns(:talk).reload
    assert_equal 'title x', assigns(:talk).title
    assert_equal users(:one), assigns(:talk).user
    assert_equal issues(:issue2).title, assigns(:talk).issue.title
  end

  test '세상에 없었던 새로운 이슈를 넣으면 저장이 안되요' do
    sign_in(users(:one))

    previous_count = Talk.count
    post talks_path(talk: { link: 'link' }, comment_body: 'body', issue_title: 'undefined')
    assert_equal previous_count, Talk.count
  end
end