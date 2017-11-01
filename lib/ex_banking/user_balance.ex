defmodule ExBanking.UserBalance do
  use GenServer
  defstruct [:currency, :amount, :amount_number]

  alias ExBanking.User
  alias ExBanking.Actions.{Deposit, Withdraw, GetBalance, Send}
  alias __MODULE__
  alias Decimal, as: D

  @initial_balance D.new(0)

  defmodule BalanceOperation do
    defstruct [:user,
               :currency,
               :initial_balance,
               :on_new_balance,
               :on_existing_balance]
  end

  def handle(%Deposit{user: user, amount: amount, currency: currency}) do
    op = %BalanceOperation{
      user: user,
      currency: currency,
      initial_balance: amount,
      on_new_balance: fn() ->
        {:ok, new_balance(currency, amount)}
      end,
      on_existing_balance: fn(pid) ->
        GenServer.call(pid, {:deposit, amount})
      end
    }
    apply_balance_op(op)
  end

  def handle(%Withdraw{user: user, amount: amount, currency: currency}) do
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

  def handle(%GetBalance{user: user, currency: currency}) do
    op = %BalanceOperation{
      user: user,
      currency: currency,
      initial_balance: @initial_balance,
      on_new_balance: fn() -> {:ok, new_balance(currency, @initial_balance)} end,
      on_existing_balance: fn(pid) -> GenServer.call(pid, :get_balance) end
    }
    apply_balance_op(op)
  end

  def handle(%Send{from: sender, to: receiver, currency: currency, amount: amount}) do
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
      balance: new_balance(currency, amount)
    }}
  end

  def handle_call({:deposit, amount}, _from, %{balance: balance} = state) do
    new_amount = Decimal.add(balance.amount, amount)
    new_balance = %{balance | amount: new_amount, amount_number: to_number(new_amount)}
    new_state = %{state | balance: new_balance}

    {:reply, {:ok, new_balance}, new_state}
  end

  def handle_call({:withdraw, amount}, _from, %{balance: balance} = state)
  do
    with {:ok, new_balance} <- subtract_amount(balance, amount)
    do
      new_state = %{state | balance: new_balance}
      {:reply, {:ok, new_balance}, new_state}
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
        with {:ok, new_sender_balance} <- subtract_amount(balance, amount)
        do
          new_sender_state = %{state | balance: new_sender_balance}

          {:reply, {:ok, new_sender_balance, new_balance(balance.currency, amount)}, new_sender_state}
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

          {:reply, {:ok, new_balance, new_receiver_balance}, new_state}
        else
          {:error, error} ->
            {:reply, {:error, error}, state}
        end
      end
    }

    apply_balance_op(op)
  end

  def handle_call(:get_balance, _from, %{balance: balance} = state) do
    {:reply, {:ok, balance}, state}
  end

  # Private API
  defp apply_balance_op(%BalanceOperation{user: user, currency: currency, initial_balance: balance} = op) do
    name = via_tuple(user, currency)
    case GenServer.start_link(__MODULE__, [user, currency, balance], name: name) do
      {:ok, _pid} -> op.on_new_balance.()
      {:error, {:already_started, pid}} -> op.on_existing_balance.(pid)
    end
  end

  defp subtract_amount(balance, amount) do
    new_amount = D.sub(balance.amount, amount)
    case new_amount do
      %Decimal{sign: 1} ->
        {:ok, %{balance | amount: new_amount, amount_number: to_number(new_amount)}}
      %Decimal{sign: -1} -> {:error, :not_enough_money}
    end
  end

  defp via_tuple(name, currency) do
    key = "#{name}_#{currency}"
    {:via, Registry, {ExBanking.UserRegistry, key}}
  end

  defp new_balance(currency, amount) do
    %UserBalance{currency: currency, amount: amount, amount_number: to_number(amount)}
  end

  defp to_number(decimal) do
    D.to_float(decimal)
  end
end
