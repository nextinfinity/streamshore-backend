defmodule Dictionary do
  @moduledoc false

  @adjectives ~w(
    agile
    bright
    calm
    clever
    cosmic
    curious
    daring
    eager
    gentle
    joyful
    lively
    lucky
    noble
    radiant
    swift
    vivid
    witty
  )

  @animals ~w(
    badger
    dolphin
    falcon
    fox
    gecko
    heron
    lynx
    otter
    owl
    panther
    raven
    seal
    tiger
    wolf
    yak
  )

  @words @adjectives ++ @animals

  def random_word, do: Enum.random(@words)
  def random_adjective, do: Enum.random(@adjectives)
  def random_animal, do: Enum.random(@animals)
end
