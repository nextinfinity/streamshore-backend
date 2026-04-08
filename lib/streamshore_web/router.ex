defmodule StreamshoreWeb.Router do
  use StreamshoreWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
    plug StreamshoreWeb.Plugs.LoadAuth
  end

  scope "/api", StreamshoreWeb do
    pipe_through :api

    resources "/session", SessionController, only: [:create, :delete]

    resources "/users", UserController, except: [:new, :edit] do
      resources "/friends", FriendController, only: [:index, :create, :update, :delete]
      resources "/favorites", FavoriteController, only: [:index, :show, :create, :delete]

      resources "/playlists", PlaylistController, only: [:index, :create, :update, :delete] do
        resources "/videos", PlaylistVideoController, only: [:index, :create, :delete]
      end
    end

    resources "/rooms", RoomController, except: [:new] do
      resources "/videos", VideoController, only: [:create, :update, :delete]
      resources "/permissions", PermissionController, only: [:index, :show, :update]
    end
  end
end
