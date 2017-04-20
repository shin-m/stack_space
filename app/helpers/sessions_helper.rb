module SessionsHelper
  def log_in(user)
    session[:user_id] = user.id
    remember(user)
  end

  def log_out
    return unless logged_in?

    forget(current_user)
    session.delete(:user_id)
    @current_user = nil
  end

  def current_user
    raise <<-EOS if (cookies.signed[:user_id].nil? && session[:user_id])
cookieのユーザIDがnilの場合はセッションのユーザIDもnilである必要があります。\n
(session[:user_id]: #{session[:user_id]})
    EOS

    if (user_id = session[:user_id])
      @current_user ||= User.find_by(id: user_id)
    elsif (user_id = cookies.signed[:user_id])
      @current_user = authenticated_user(user_id)
    end
  end

  def logged_in?
    !current_user.nil?
  end

  private

  def remember(user)
    user.remember
    cookies.permanent.signed[:user_id] = user.id
    cookies.permanent[:remember_token] = user.remember_token
  end

  def forget(user)
    user.forget
    cookies.delete(:user_id)
    cookies.delete(:remember_token)
  end

  def authenticated_user(user_id)
    user = User.find_by(id: user_id)
    return unless user && user.authenticated?(cookies[:remember_token])

    log_in(user)
    user
  end
end
