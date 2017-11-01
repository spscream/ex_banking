defmodule ExBanking.Actions.CreateUser do
  defstruct [:user, :requests_limit]
  alias __MODULE__
  @requests_limit Application.get_env(:ex_banking, :requests_limit, 10)

  def make(user, requests_limit \\ @requests_limit)
  def make(user, requests_limit) when is_binary(user) do
    {:ok, %CreateUser{user: user, requests_limit: requests_limit}}
  end
  def make(_name, _requests_limit) do
    {:error, :wrong_arguments}
  end
end
