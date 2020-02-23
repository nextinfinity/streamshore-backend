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
    resources "/session", SessionController, except: [:index, :edit, :update]

    resources "/users", UserController do
      resources "/playlists", PlaylistController do
        resources "/videos", PlaylistVideoController
      end
    end

    resources "/rooms", RoomController do
      resources "/videos", VideoController
    end
  end

end
