defmodule Streamshore.Room do
    use Ecto.Schema
    import Ecto.Changeset
    alias Streamshore.PermissionLevel

    schema "rooms" do
        field :name, :string, unique: true
        field :motd, :string, default: ""
        field :privacy, :integer
        field :owner, :string
        field :route, :string, unique: true
        field :thumbnail, :string, default: nil
        field :queue_level, :integer, default: PermissionLevel.user()
        field :anon_queue, :integer, default: 1
        field :queue_limit, :integer, default: 0
        field :chat_level, :integer, default: PermissionLevel.user()
        field :anon_chat, :integer, default: 1
        field :chat_filter, :integer, default: 0
        field :vote_threshold, :integer, default: 50
        field :vote_enable, :integer, default: 1
        timestamps()
    end

    def changeset(room, params \\ %{}) do
        room
        |> cast(params, [:name, :motd, :privacy, :owner, :route, :thumbnail, :queue_level, :anon_queue, :chat_level, :anon_chat, :chat_filter, :vote_threshold])
        |> validate_required([:name])
        |> validate_required([:owner])
        |> validate_required([:route])
        |> validate_length(:name, min: 1, max: 32)
        |> validate_length(:route, min: 1, max: 32)
        |> unique_constraint(:name)
        |> unique_constraint(:route)
    end

end