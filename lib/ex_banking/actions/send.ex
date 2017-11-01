defmodule ExBanking.Actions.Send do
  defstruct [:from, :to, :amount, :currency]
  alias __MODULE__
  alias Decimal, as: D
  @precision Application.get_env(:ex_banking, :precision, 2)

  def make(from_user, to_user, amount, currency)
  when is_binary(from_user)
   and is_binary(to_user)
   and is_number(amount)
   and amount > 0
   and is_binary(currency)
  do
    decimal = amount |> D.new() |> D.round(@precision)
    {:ok, %Send{from: from_user, to: to_user, amount: decimal, currency: currency}}
  end

  def make(_from_user, _to_user, _amount, _currency) do
    {:error, :wrong_arguments}
  end
end
