defmodule ExBanking.Actions.Deposit do
  defstruct [:user, :amount, :currency]
  alias __MODULE__

  def make(user, amount, currency)
  when is_binary(user)
   and is_number(amount)
   and amount > 0
   and is_binary(currency)
  do
    {:ok, %Deposit{user: user, amount: amount, currency: currency}}
  end

  def make(_user, _amount, _currency) do
    {:error, :wrong_arguments}
  end
end
