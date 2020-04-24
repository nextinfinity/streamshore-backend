# ./Dockerfile

# Extend from the official Elixir image
FROM circleci/elixir:1.10.1
USER root

ARG DB
ARG SECRET
ARG DOMAIN
ARG FRONTEND
ARG SENDGRID_KEY

# Install NPM
# install curl
RUN apt-get install curl
# get install script and pass it to execute:
RUN curl -sL https://deb.nodesource.com/setup_12.x | bash
# and install node
RUN apt-get install -y nodejs

# Create app directory and copy the Elixir projects into it
RUN mkdir /app
COPY . /app

RUN mkdir /cert

WORKDIR /cert
RUN openssl req -x509 -newkey rsa:4096 -nodes -keyout privkey.pem -out cert.pem -days 1 -subj '/CN=$DOMAIN'

WORKDIR /app/assets
RUN npm install

WORKDIR /app

ENV MIX_ENV=prod
ENV DATABASE_URL=$DB
ENV SECRET_KEY_BASE=$SECRET
ENV DOMAIN=$DOMAIN
ENV FRONTEND=$FRONTEND
ENV EMAIL_KEY=$SENDGRID_KEY
# Install hex package manager
# By using --force, we don’t need to type “Y” to confirm the installation
RUN mix local.hex --force
RUN mix local.rebar --force
RUN mix deps.get
RUN mix ecto.create
RUN mix ecto.migrate

# Compile the project
CMD mix phx.server