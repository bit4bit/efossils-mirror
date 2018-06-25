defmodule Efossils.CommandTest do
  use Efossils.DataCase

  describe "command" do
    test "init_repository/2 returns {:ok, db_path}" do
      {:ok, ctx} = Efossils.Command.init_repository("test", "grouptest")
      assert File.exists?(Keyword.get(ctx, :db_path)) == true
    end

    test "new_user/4 returns :ok" do
      {:ok, ctx} = Efossils.Command.init_repository("test", "grouptest")
      assert Efossils.Command.new_user(ctx, "aba", "aba", "ebo") == {:ok, ctx}
      assert Efossils.Command.new_user(ctx, "abo", 55, "ebo") == {:ok, ctx}
    end
  end
end
