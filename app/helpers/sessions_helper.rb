module SessionsHelper
  # log in for user
  def log_in(user)
    session[:user_id] = user.id
  end

  # remember user
  def remember(user)
    user.remember
    cookies.permanent.signed[:user_id] = user.id
    cookies.permanent[:remember_token] = user.remember_token
  end

  # return true if given user equals current user
  def current_user?(user)
    user == current_user
  end

  # return current user logged in if exists
  def current_user
    if (user_id = session[:user_id])
      @current_user ||= User.find_by(id: user_id)
    elsif (user_id = cookies.signed[:user_id])
      user = User.find_by(id: user_id)
      if user && user.authenticated?(cookies[:remember_token])
        log_in user
        @current_user = user
      end
    end
  end

  # return true if user logged in
  def logged_in?
    !current_user.nil?
  end

  # delete permanent cookie
  def forget(user)
    user.forget
    cookies.delete(:user_id)
    cookies.delete(:remember_token)
  end

  # log out for user
  def log_out
    forget(current_user)
    session.delete :user_id
    @current_user = nil
  end

  # redirect back to remembered URL or default
  def redirect_back_or(default)
    redirect_to(session[:forwarding_url] || default)
    session.delete(:forwarding_url)
  end

  # remember URL to access
  def store_location
    session[:forwarding_url] = request.original_url if request.get?
  end
end
