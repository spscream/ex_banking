defmodule ExBanking.User do
  use GenServer

  alias ExBanking.Actions.{CreateUser, Deposit, Withdraw, GetBalance, Send}
  alias ExBanking.{UserRegistry, UserBalance}


  defstruct [:name, :requests, :requests_limit]
  alias __MODULE__

  def start_link(user, requests_limit) do
      case GenServer.start_link(__MODULE__, [user, requests_limit], name: via_tuple(user)) do
        {:ok, _pid} -> :ok
        {:error, {:already_started, _pid}} -> {:error, :already_exists}
      end
  end

  def handle(%CreateUser{user: user, requests_limit: requests_limit}) do
    if user_exists?(user) do
      {:error, :already_exists}
    else
      start_link(user, requests_limit)
    end
  end

  def handle(%Deposit{user: user} = op) do
    exec_with_user(user, fn() ->
      with {:ok, balance} <- UserBalance.handle(op)
      do
        {:ok, balance.amount_number}
      end
    end)
  end

  def handle(%Withdraw{user: user} = op) do
    exec_with_user(user, fn() ->
      with {:ok, balance} <- UserBalance.handle(op)
      do
        {:ok, balance.amount_number}
      end
    end)
  end

  def handle(%GetBalance{user: user} = op) do
    exec_with_user(user, fn() ->
      with {:ok, balance} <- UserBalance.handle(op)
      do
        {:ok, balance.amount_number}
      end
    end)
  end

  def handle(%Send{from: sender, to: receiver} = op) do
    exec_with_user(sender, fn() ->
      exec_with_user(receiver, fn() ->
        with {:ok, sender_balance, receiver_balance} <-
          UserBalance.handle(op)
        do
          {:ok, sender_balance.amount_number, receiver_balance.amount_number}
        end
      end,
      :receiver_does_not_exist,
      :too_many_requests_to_receiver
      )
    end,
    :sender_does_not_exist,
    :too_many_requests_to_sender)
  end

  def apply_func(user, func, on_missing_user_error) do
    name = via_tuple(user)
    GenServer.call(name, {:apply, func, on_missing_user_error})
  end

  # GenServer API

  def init([user, requests_limit]) do
    {:ok, %User{name: user, requests: 0, requests_limit: requests_limit}}
  end

  def handle_call({:apply, _func, error_code}, _from,
                  %{requests: requests, requests_limit: requests_limit} = state)
  when requests >= requests_limit
  do
    {:reply, {:error, error_code}, state}
  end
  def handle_call({:apply, func, _error_code}, from, state) do
    user_pid = self()

    Task.start(fn() ->
      response = func.()
      GenServer.cast(user_pid, :response_complete)
      GenServer.reply(from, response)
    end)

    {:noreply, %{state | requests: state.requests + 1}}
  end

  def handle_cast(:response_complete, state) do
    {:noreply, %{state | requests: state.requests - 1}}
  end

  defp exec_with_user(
    user,
    func,
    on_missing_user_error \\ :user_does_not_exist,
    on_rate_exceeded_error \\ :too_many_requests_to_user
  )
  do
    if user_exists?(user) do
      apply_func(user, func, on_rate_exceeded_error)
    else
      error(on_missing_user_error)
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

  defp error(error) do
    {:error, error}
  end
end
