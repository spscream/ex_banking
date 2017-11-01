defmodule ExBanking.User do
  use GenServer

  alias ExBanking.Actions.{CreateUser, Deposit, Withdraw, GetBalance, Send}
  alias ExBanking.{UserRegistry, UserBalance}

  defstruct [:name]
  alias __MODULE__

  def start_link(user) do
      case GenServer.start_link(__MODULE__, [user], name: via_tuple(user)) do
        {:ok, _pid} -> :ok
        {:error, {:already_started, _pid}} -> {:error, :already_exists}
      end
  end

  def handle(%CreateUser{user: user}) do
    if user_exists?(user) do
      {:error, :already_exists}
    else
      start_link(user)
    end
  end

  def handle(%Deposit{user: user, amount: amount, currency: currency}) do
    exec_with_user(user, fn() ->
      with {:ok, balance} <-UserBalance.deposit(user, amount, currency)
      do
        {:ok, balance.amount_number}
      end
    end)
  end

  def handle(%Withdraw{user: user, amount: amount, currency: currency}) do
    exec_with_user(user, fn() ->
      with {:ok, balance} <- UserBalance.withdraw(user, amount, currency)
      do
        {:ok, balance.amount_number}
      end
    end)
  end

  def handle(%GetBalance{user: user, currency: currency}) do
    exec_with_user(user, fn() ->
      with {:ok, balance} <- UserBalance.get_balance(user, currency)
      do
        {:ok, balance.amount_number}
      end
    end)
  end

  def handle(%Send{from: sender, to: receiver, amount: amount, currency: currency}) do
    exec_with_user(sender, fn() ->
      exec_with_user(receiver, fn() ->
        with {:ok, sender_balance, receiver_balance} <- UserBalance.send(sender, receiver, amount, currency)
        do
          {:ok, sender_balance.amount_number, receiver_balance.amount_number}
        end
      end,
      fn() -> {:error, :receiver_does_not_exist} end)
    end,
    fn() -> {:error, :sender_does_not_exist} end)
  end

  # User API

  # GenServer API
  def init(user) do
    {:ok, %User{name: user}}
  end

  defp exec_with_user(user, func, on_error \\ fn() -> {:error, :user_does_not_exist} end) do
    if user_exists?(user) do
      func.()
    else
      on_error.()
    end
  end

  # Private API

  defp user_exists?(user) do
    case Registry.lookup(UserRegistry, user) do
      [] -> false
      [_proc] -> true
    end
  end

  defp via_tuple(name) do
    {:via, Registry, {UserRegistry, name}}
  end
end
