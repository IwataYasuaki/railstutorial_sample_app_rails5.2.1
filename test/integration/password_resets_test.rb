require 'test_helper'

class PasswordResetsTest < ActionDispatch::IntegrationTest
  def setup
    ActionMailer::Base.deliveries.clear
    @user = users(:michael)
  end

  test "password resets" do
    get new_password_reset_path
    assert_template 'password_resets/new'
    # invalid email
    post password_resets_path, params: { password_reset: { email: "" } }
    assert_not flash.empty?
    assert_template 'password_resets/new'
    # valid email
    post password_resets_path, params: { password_reset: { email: @user.email } }
    assert_not_equal @user.reset_digest, @user.reload.reset_digest
    assert_equal 1, ActionMailer::Base.deliveries.size
    assert_not flash.empty?
    assert_redirected_to root_url
    # test for password reset form
    user = assigns(:user)
    # invalid email
    get edit_password_reset_path(user.reset_token, email: "")
    assert_redirected_to root_url
    # invalid user
    user.toggle!(:activated)
    get edit_password_reset_path(user.reset_token, email: user.email)
    assert_redirected_to root_url
    user.toggle!(:activated)
    # valid email and invalid token
    get edit_password_reset_path('wrong token', email: user.email)
    assert_redirected_to root_url
    # valid email and valid token
    get edit_password_reset_path(user.reset_token, email: user.email)
    assert_template 'password_resets/edit'
    assert_select "input[name=email][type=hidden][value=?]", user.email
    # invalid password and password confirmation
    prms = { email: user.email, user: { password: "foobaz", password_confirmation: "barquux" } }
    patch password_reset_path(user.reset_token), params: prms
    assert_select 'div#error_explanation'
    # empty password
    prms = { email: user.email, user: { password: "", password_confirmation: "" } }
    patch password_reset_path(user.reset_token), params: prms
    assert_select 'div#error_explanation'
    # valid password and password confirmation
    prms = { email: user.email, user: { password: "foobaz", password_confirmation: "foobaz" } }
    patch password_reset_path(user.reset_token), params: prms
    assert is_logged_in?
    assert_not flash.empty?
    assert_redirected_to user
    assert_nil user.reload.reset_digest
  end

  test "expired token" do
    get new_password_reset_path
    post password_resets_path, params: { password_reset: { email: @user.email } }
    @user = assigns(:user)
    @user.update_attribute(:reset_sent_at, 3.hours.ago)
    #get edit_password_reset_path(@user.reset_token, email: @user.email)
    prms = { email: @user.email, user: { password: "foobar", password_confirmation: "foobar" } }
    patch password_reset_path(@user.reset_token), params: prms
    assert_response :redirect
    follow_redirect!
    assert_match /Password reset has expired/i, response.body
    end
end
