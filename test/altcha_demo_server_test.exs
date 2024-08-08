defmodule AltchaDemoServerTest do
  use ExUnit.Case
  doctest AltchaDemoServer

  test "greets the world" do
    assert AltchaDemoServer.hello() == :world
  end
end
