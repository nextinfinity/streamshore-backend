defmodule StreamshoreWeb.Router do
  use StreamshoreWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
    plug StreamshoreWeb.Plugs.LoadAuth
  end

  scope "/api", StreamshoreWeb do
    pipe_through :api

    post "/request-password-reset", ResetPasswordController, :request_password_reset
    post "/reset-password", ResetPasswordController, :reset_password
    post "/resend-email-verification", VerifyEmailController, :resend_email_verification
    post "/verify-email", VerifyEmailController, :verify_email

    resources "/accounts", AccountController, only: [:create]
    resources "/account", AccountController, only: [:delete], singleton: true do
      put "/password", AccountController, :update_password, as: "update_password"

      resources "/friends", FriendController, only: [:index, :create, :update, :delete]
      resources "/favorites", FavoriteController, only: [:index, :show, :create, :delete]

      resources "/playlists", PlaylistController, only: [:index, :create, :update, :delete] do
        resources "/videos", PlaylistVideoController, only: [:index, :create, :delete]
      end
    end

    resources "/session", SessionController, only: [:create, :delete], singleton: true

    resources "/users", UserController, only: [:index, :show]

    resources "/rooms", RoomController, except: [:new] do
      resources "/videos", VideoController, only: [:create, :update, :delete]
      resources "/permissions", PermissionController, only: [:index, :show, :update]
    end
  end
end
