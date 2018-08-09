defmodule Efossils.Command.CollaborativeTest do
  use Efossils.DataCase
  
  describe "collaborative" do
    test "init_repository/2" do
      {:ok, ctx} = Efossils.Command.init_repository("testcollab", "collabtest")
      {:ok, _} = Efossils.Command.config_import(ctx, "fossil.ticket.skin")
      {:ok, _} = Efossils.Command.Collaborative.append_assigned_to(ctx, "user")
      {:ok, _} = Efossils.Command.Collaborative.append_assigned_to(ctx, "nuevouser")
      {:ok, _} = Efossils.Command.Collaborative.append_assigned_to(ctx, "nuovouser")
    end
  end
end
