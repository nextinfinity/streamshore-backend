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
    resources "/session", SessionController, except: [:index, :new, :edit, :update]

    resources "/users", UserController, except: [:new, :edit] do
      resources "/playlists", PlaylistController, except: [:new, :edit]  do
        resources "/videos", PlaylistVideoController, except: [:new, :edit]
      end
    end

    resources "/rooms", RoomController do
      resources "/videos", VideoController
      resources "/permissions", PermissionController, only: [:index, :show, :update]
    end
  end

end
