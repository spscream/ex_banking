defmodule ExBanking do
  @moduledoc """
  This module provides public API for spheric banking app in vacuum.

  Written as a result of test task here: https://github.com/heathmont/elixir-test
  """

  alias ExBanking.User
  alias ExBanking.Actions.{CreateUser, Deposit, Withdraw, Send, GetBalance}

  @type banking_error :: {:error,
    :wrong_arguments                |
    :user_already_exists            |
    :user_does_not_exist            |
    :not_enough_money               |
    :sender_does_not_exist          |
    :receiver_does_not_exist        |
    :too_many_requests_to_user      |
    :too_many_requests_to_sender    |
    :too_many_requests_to_receiver
  }

  @doc """
  Function creates new user in the system with default requests limit.
  New user has zero balance of any currency
  """
  @spec create_user(user :: String.t) :: :ok  | banking_error
  def create_user(user) do
    apply_operation(CreateUser.make(user))
  end

  @doc """
  Function creates new user in the system with specified rate limit.
  New user has zero balance of any currency
  """
  @spec create_user(user :: String.t, requests_limit :: integer) :: :ok | banking_error
  def create_user(user, requests_limit) do
    apply_operation(CreateUser.make(user, requests_limit))
  end

  @doc """
  Increases user's balance in given currency by amount value
  Returns new_balance of the user in given format
  """
  @spec deposit(user :: String.t, amount :: number, currency :: String.t) :: {:ok, new_balance :: number} | banking_error
  def deposit(user, amount, currency) do
    apply_operation(Deposit.make(user, amount, currency))
  end

  @doc """
  Decreases user's balance in given currency by amount value
  Returns new_balance of the user in given format
  """
  @spec withdraw(user :: String.t, amount :: number, currency :: String.t) :: {:ok, new_balance :: number} | banking_error
  def withdraw(user, amount, currency) do
    apply_operation(Withdraw.make(user, amount, currency))
  end

  @doc """
  Returns balance of the user in given formatk
  """
  @spec get_balance(user :: String.t, currency :: String.t) :: {:ok, balance :: number} | banking_error
  def get_balance(user, currency) do
    apply_operation(GetBalance.make(user, currency))
  end

  @doc """
  Decreases from_user's balance in given currency by amount value
  Increases to_user's balance in given currency by amount value
  Returns balance of from_user and to_user in given format
  """
  @spec send(from_user :: String.t, to_user :: String.t, amount :: number, currency :: String.t) :: {:ok, from_user_balance :: number, to_user_balance :: number} | banking_error
  def send(from_user, to_user, amount, currency) do
    apply_operation(Send.make(from_user, to_user, amount, currency))
  end

  defp apply_operation({:ok, operation}) do
    User.handle(operation)
  end
  defp apply_operation(error) do
    error
  end
end
