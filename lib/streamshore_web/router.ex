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

  scope "/user", StreamshoreWeb do
    pipe_through :browser

    get "/anon", UserController, :get_anon
  end

  # Other scopes may use custom stacks.
  # scope "/api", StreamshoreWeb do
  #   pipe_through :api
  # end
end
