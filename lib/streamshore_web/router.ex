defmodule StreamshoreWeb.Router do
  use StreamshoreWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", StreamshoreWeb do
    pipe_through :browser

    get "/", PageController, :index
  end


  scope "/api", StreamshoreWeb do
    pipe_through :api

    # TODO: do we even need show here? trying to limit vulnerabilities
    resources "/session", SessionController, only: [:create, :delete]

    resources "/emails", EmailController, only: [:create]

    resources "/users", UserController, except: [:new, :edit] do
      resources "/friends", FriendController, only: [:index, :create, :update, :delete]
      resources "/favorites", FavoriteController, only: [:index, :show, :create, :delete]
      resources "/playlists", PlaylistController, except: [:new, :edit]  do
        resources "/videos", PlaylistVideoController, only: [:index, :create, :update, :delete]
      end
    end

    resources "/rooms", RoomController, except: [:new] do
      resources "/videos", VideoController, only: [:create, :update, :delete]
      resources "/permissions", PermissionController, only: [:index, :show, :update]
    end
  end

end
