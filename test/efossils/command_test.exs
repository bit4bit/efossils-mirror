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

    test "password_user/3 returns :ok" do
      {:ok, ctx} = Efossils.Command.init_repository("test", "grouptest")
      assert Efossils.Command.new_user(ctx, "aba", "aba", "ebo") == {:ok, ctx}
      assert Efossils.Command.password_user(ctx, "aba", "haber") == {:ok, ctx}
      assert Efossils.Command.password_user(ctx, "aboeu", "oo") == {:error, :user_not_exists}
    end

    test "timeline/2 returns {:ok, lines}" do
      date = Date.utc_today()
      {:ok, ctx} = Efossils.Command.init_repository("test", "grouptest")
      {:ok, {date, timelines}} = Efossils.Command.timeline(ctx, date)
      assert length(timelines) > 0
    end

    test "git migration without password returns {:ok, path}" do
      {:ok, migrate_path} = Efossils.Command.migrate_repository(:git, "https://github.com/elixir-plug/plug/")
    end

    test "git migration and init without password returns {:ok, }" do
      {:ok, migrate_path} = Efossils.Command.migrate_repository(:git, "https://github.com/elixir-plug/plug/")
      {:ok, ctx} = Efossils.Command.init_from_db(migrate_path, "test", "migration")
      assert File.exists?(Keyword.get(ctx, :db_path)) == true
    end
    
  end

end
