module SessionsHelper
  # log in for user
  def log_in(user)
    session[:user_id] = user.id
  end

  # return current user logged in if exists
  def current_user
    @current_user ||= User.find_by(id: session[:user_id])
  end

  # return true if user logged in
  def logged_in?
    !current_user.nil?
  end

  # log out for user
  def log_out
    session.delete :user_id
    @current_user = nil
  end
end
