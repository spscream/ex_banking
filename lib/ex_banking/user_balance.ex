defmodule ExBanking.UserBalance do
  use GenServer
  defstruct [:currency, :amount]

  alias ExBanking.{User}
  alias __MODULE__

  @initial_balance 0

  defmodule BalanceOperation do
    defstruct [:user,
               :currency,
               :initial_balance,
               :on_new_balance,
               :on_existing_balance]
  end

  def deposit(user, amount, currency) do
    op = %BalanceOperation{
      user: user,
      currency: currency,
      initial_balance: amount,
      on_new_balance: fn() ->
        {:ok, amount}
      end,
      on_existing_balance: fn(pid) ->
        GenServer.call(pid, {:deposit, amount})
      end
    }
    apply_balance_op(op)
  end

  def withdraw(user, amount, currency) do
    op = %BalanceOperation{
      user: user,
      currency: currency,
      initial_balance: @initial_balance,
      on_new_balance: fn() ->
        {:error, :not_enough_money}
      end,
      on_existing_balance: fn(pid) ->
        GenServer.call(pid, {:withdraw, amount})
      end
    }
    apply_balance_op(op)
  end

  def get_balance(user, currency) do
    op = %BalanceOperation{
      user: user,
      currency: currency,
      initial_balance: @initial_balance,
      on_new_balance: fn() -> {:ok, 0} end,
      on_existing_balance: fn(pid) -> GenServer.call(pid, :get_balance) end
    }
    apply_balance_op(op)
  end

  def send(sender, receiver, amount, currency) do
    op = %BalanceOperation{
      user: sender,
      currency: currency,
      initial_balance: @initial_balance,
      on_new_balance: fn() -> {:error, :not_enough_money} end,
      on_existing_balance: fn(pid) ->
        GenServer.call(pid, {:send, receiver, amount})
      end
    }
    apply_balance_op(op)
  end

  # GenServer API

  def init([user, currency, amount]) do
    {:ok, %{
      user: %User{name: user},
      balance: %UserBalance{
        currency: currency,
        amount: amount
      }
    }}
  end

  def handle_call({:deposit, amount}, _from, %{balance: balance} = state) do
    new_balance = %{balance | amount: balance.amount + amount}
    new_state = %{state | balance: new_balance}

    {:reply, {:ok, new_balance.amount}, new_state}
  end

  def handle_call({:withdraw, amount}, _from, %{balance: balance} = state)
  do
    with {:ok, new_balance} <- subtract_amount(balance, amount)
    do
      new_state = %{state | balance: new_balance}
      {:reply, {:ok, new_balance.amount}, new_state}
    else
      {:error, error} ->
        {:reply, {:error, error}, state}
    end
  end


  def handle_call({:send, receiver, amount}, _from, %{balance: balance} = state) do
    op = %BalanceOperation{
      user: receiver,
      currency: balance.currency,
      initial_balance: amount,
      on_new_balance: fn() ->
        with {:ok, new_balance} <- subtract_amount(balance, amount)
        do
          new_state = %{state | balance: new_balance}

          {:reply, {:ok, new_balance.amount, amount}, new_state}
        else
          {:error, error} ->
            {:reply, {:error, error}, state}
        end
      end,
      on_existing_balance: fn(pid) ->
        with {:ok, new_balance} <- subtract_amount(balance, amount),
             {:ok, new_receiver_balance} <- GenServer.call(pid, {:deposit, amount})
        do
          new_state = %{state | balance: new_balance}

          {:reply, {:ok, new_balance.amount, new_receiver_balance}, new_state}
        else
          {:error, error} ->
            {:reply, {:error, error}, state}
        end
      end
    }

    apply_balance_op(op)
  end

  def handle_call(:get_balance, _from, %{balance: balance} = state) do
    {:reply, {:ok, balance.amount}, state}
  end
  # Private API


  defp apply_balance_op(%BalanceOperation{user: user, currency: currency, initial_balance: balance} = op) do
    name = via_tuple(user, currency)
    case GenServer.start_link(__MODULE__, [user, currency, balance], name: name) do
      {:ok, _pid} -> op.on_new_balance.()
      {:error, {:already_started, pid}} -> op.on_existing_balance.(pid)
    end
  end

  defp via_tuple(name, currency) do
    key = "#{name}_#{currency}"
    {:via, Registry, {ExBanking.UserRegistry, key}}
  end

  defp subtract_amount(balance, amount) do
    new_amount = balance.amount - amount
    cond do
      new_amount >= 0 ->
        {:ok, %{balance | amount: new_amount}}

      new_amount < 0 ->
        {:error, :not_enough_money}
    end
  end
end
