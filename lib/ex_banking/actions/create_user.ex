defmodule ExBanking.Actions.CreateUser do
  defstruct [:user]
  alias __MODULE__

  def make(user) when is_binary(user) do
    {:ok, %CreateUser{user: user}}
  end
  def make(_name) do
    {:error, :wrong_arguments}
  end
end
