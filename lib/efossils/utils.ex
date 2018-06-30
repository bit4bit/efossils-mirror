defmodule Efossils.Utils do

  def build_lower_name(changeset) do
    if name = Ecto.Changeset.get_change(changeset, :name) do
      Ecto.Changeset.put_change(changeset, :lower_name, lower_name(name))
    else
      changeset
    end
  end
  
  def lower_name(name) do
    Regex.replace(~r/[^\w]/, String.downcase(name), "_")
  end
end
