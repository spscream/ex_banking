defmodule ExBanking.Actions.GetBalance do
  defstruct [:user, :currency]
  alias __MODULE__

  def make(user, currency)
  when is_binary(user)
   and is_binary(currency)
  do
    {:ok, %GetBalance{user: user, currency: currency}}
  end

  def make(_user, _currency) do
    {:error, :wrong_arguments}
  end
end
