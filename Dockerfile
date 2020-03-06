# ./Dockerfile

# Extend from the official Elixir image
FROM circleci/elixir:1.10.1

# Create app directory and copy the Elixir projects into it
RUN mkdir /app
COPY . /app

WORKDIR /app/assets
npm install

WORKDIR /app

ENV MIX_ENV=prod
# Install hex package manager
# By using --force, we don’t need to type “Y” to confirm the installation
RUN mix local.hex --force
RUN mix local.rebar --force
RUN mix deps.get
RUN mix ecto.create
RUN mix ecto.migrate

# Compile the project
CMD mix phx.server