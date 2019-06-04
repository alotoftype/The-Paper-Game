require 'test_helper'

class GameUsersControllerTest < ActionController::TestCase
  setup do
    @game_user = game_users(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:game_users)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create game_user" do
    assert_difference('GameUser.count') do
      post :create, :game_user => @game_user.attributes
    end

    assert_redirected_to game_user_path(assigns(:game_user))
  end

  test "should show game_user" do
    get :show, :id => @game_user.to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => @game_user.to_param
    assert_response :success
  end

  test "should update game_user" do
    put :update, :id => @game_user.to_param, :game_user => @game_user.attributes
    assert_redirected_to game_user_path(assigns(:game_user))
  end

  test "should destroy game_user" do
    assert_difference('GameUser.count', -1) do
      delete :destroy, :id => @game_user.to_param
    end

    assert_redirected_to game_users_path
  end
end
