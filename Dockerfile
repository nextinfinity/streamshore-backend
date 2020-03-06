# ./Dockerfile

# Extend from the official Elixir image
FROM circleci/elixir:1.10.1
USER root

# Install NPM
# install curl
RUN apt-get install curl
# get install script and pass it to execute:
RUN curl -sL https://deb.nodesource.com/setup_12.x | bash
# and install node
RUN apt-get install nodejs

# Create app directory and copy the Elixir projects into it
RUN mkdir /app
COPY . /app

WORKDIR /app/assets
RUN npm install

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