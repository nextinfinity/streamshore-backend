defmodule Streamshore.PermissionLevel do
  def owner do
    100
  end

  def manager do
    50
  end

  def approved do
    25
  end

  def user do
    10
  end

  def muted do
    5
  end

  def banned do
    0
  end
end
