defmodule ExBankingTest do
  use ExUnit.Case, async: true

  setup do
    user = random_string(10)

    {:ok, user: user}
  end

  describe "#create_user/1 with valid param" do
    test "creates user", %{user: user} do
      assert :ok == ExBanking.create_user(user)
    end
  end

  describe "#create_user/1 with invalid param type" do
    test "returns {:error, :wrong_arguments}" do
      wrong_arguments = [nil, ["list"], %{}]
      for arg <- wrong_arguments do
        assert {:error, :wrong_arguments} == ExBanking.create_user(arg)
      end
    end
  end

  describe "#create_user/1 with name of existing user" do
    test "returns {:error, :already_exists}", %{user: user} do
      ExBanking.create_user(user)
      assert {:error, :already_exists} == ExBanking.create_user(user)
    end
  end

  describe "#deposit/3 with valid params and new currency" do
    test "returns {:ok, new_balance}", %{user: user} do
      ExBanking.create_user(user)
      assert {:ok, 100} == ExBanking.deposit(user, 100, "rub")
    end
  end

  describe "#deposit/3 with valid params and existing currency" do
    test "returns {:ok, new_balance} where new_balance is currency balance + amount", %{user: user} do
      ExBanking.create_user(user)
      assert {:ok, 100} == ExBanking.deposit(user, 100, "rub")
      assert {:ok, 200} == ExBanking.deposit(user, 100, "rub")
      assert {:ok, 100} == ExBanking.deposit(user, 100, "eur")
      assert {:ok, 200} == ExBanking.deposit(user, 100, "eur")
    end
  end

  describe "#deposit/3 with non-existing user" do
    test "returns {:error, :user_does_not_exist}" do
      assert {:error, :user_does_not_exist} == ExBanking.deposit("some_user", 100, "rub")
    end
  end

  describe "#deposit/3 with negative number" do
    test "returns {:error, :wrong_arguments}", %{user: user} do
      ExBanking.create_user(user)
      assert {:error, :wrong_arguments} == ExBanking.deposit(user, -100, "rub")
    end
  end

  describe "#deposit/3 with wrong currency type" do
    test "returns {:error, :wrong_arguments}", %{user: user} do
      wrong_arguments = [nil, ["list"], %{}]

      ExBanking.create_user(user)
      for arg <- wrong_arguments do
        assert {:error, :wrong_arguments} == ExBanking.deposit(user, 100, arg)
      end
    end
  end

  describe "#deposit/3 with wrong user type" do
    test "returns {:error, :wrong_arguments}" do
      wrong_arguments = [nil, ["list"], %{}]

      for arg <- wrong_arguments do
        assert {:error, :wrong_arguments} == ExBanking.deposit(arg, 100, "rub")
      end
    end
  end

  describe "#deposit/3 with wrong amount type" do
    test "returns {:error, :wrong_arguments}", %{user: user} do
      wrong_arguments = [nil, ["list"], %{}, -100]

      ExBanking.create_user(user)
      for arg <- wrong_arguments do
        assert {:error, :wrong_arguments} == ExBanking.deposit(user, arg, "rub")
      end
    end
  end

  describe "#withdraw/3 with valid params and amount <= users balance in currency" do
    test "returns {:ok, new_balance}", %{user: user} do
      ExBanking.create_user(user)
      ExBanking.deposit(user, 100, "rub")
      assert {:ok, 50} == ExBanking.withdraw(user, 50, "rub")
      assert {:ok, 0} == ExBanking.withdraw(user, 50, "rub")
    end
  end

  describe "#withdraw/3 with valid params and amount > users balance in currency" do
    test "returns {:error, :not_enough_money}", %{user: user} do
      ExBanking.create_user(user)
      ExBanking.deposit(user, 100, "rub")
      assert {:error, :not_enough_money} == ExBanking.withdraw(user, 200, "rub")
    end
  end

  describe "#withdraw/3 with valid params and having no balance in passed currency" do
    test "returns {:error, :not_enough_money}", %{user: user} do
      ExBanking.create_user(user)
      assert {:error, :not_enough_money} == ExBanking.withdraw(user, 200, "rub")
    end
  end

  describe "#withdraw/3 with non-existing user" do
    test "returns {:error, :user_does_not_exist}" do
      assert {:error, :user_does_not_exist} == ExBanking.withdraw("some_user", 200, "rub")
    end
  end

  describe "#withdraw/3 with negative number" do
    test "returns {:error, :wrong_arguments}", %{user: user} do

      ExBanking.create_user(user)
      ExBanking.deposit(user, 100, "rub")
      assert {:error, :wrong_arguments} == ExBanking.withdraw(user, -100, "rub")
    end
  end

  describe "#withdraw/3 with wrong currency type" do
    test "returns {:error, :wrong_arguments}", %{user: user} do
      wrong_arguments = [nil, ["list"], %{}]

      ExBanking.create_user(user)
      ExBanking.deposit(user, 100, "rub")

      for arg <- wrong_arguments do
        assert {:error, :wrong_arguments} == ExBanking.withdraw(user, 100, arg)
      end
    end
  end

  describe "#withdraw/3 with wrong user type" do
    test "returns {:error, :wrong_arguments}" do
      wrong_arguments = [nil, ["list"], %{}]

      for arg <- wrong_arguments do
        assert {:error, :wrong_arguments} == ExBanking.withdraw(arg, 100, "rub")
      end
    end
  end

  describe "#withdraw/3 with wrong amount type" do
    test "returns {:error, :wrong_arguments}", %{user: user} do
      wrong_arguments = [nil, ["list"], %{}]

      ExBanking.create_user(user)
      ExBanking.deposit(user, 100, "rub")

      for arg <- wrong_arguments do
        assert {:error, :wrong_arguments} == ExBanking.withdraw(user, arg, "rub")
      end
    end
  end

  describe "#get_balance/2 with valid params" do
    test "returns {:ok, balance}", %{user: user} do
      ExBanking.create_user(user)
      ExBanking.deposit(user, 100, "rub")

      assert {:ok, 100} == ExBanking.get_balance(user, "rub")
      assert {:ok, 0} == ExBanking.get_balance(user, "eur")

    end
  end

  describe "#get_balance/2 with non-existing user" do
    test "returns {:error, :user_does_not_exist}" do
      assert {:error, :user_does_not_exist} == ExBanking.get_balance("some_user", "rub")
    end
  end

  describe "#get_balance/2 with wrong user type" do
    test "returns {:error, :wrong_arguments}" do
      wrong_arguments = [nil, ["list"], %{}]

      for arg <- wrong_arguments do
        assert {:error, :wrong_arguments} == ExBanking.get_balance(arg, "rub")
      end
    end
  end

  describe "#get_balance/2 with wrong currency type" do
    test "returns {:error, :wrong_arguments}", %{user: user} do
      wrong_arguments = [nil, ["list"], %{}]

      for arg <- wrong_arguments do
        assert {:error, :wrong_arguments} == ExBanking.get_balance(user, arg)
      end
    end
  end

  describe "#send/4 with valid params and non-existing recipient balance" do
    test "returns {:ok, from_balance, to_balance}" do
      sender = random_string(16)
      receiver = random_string(16)

      ExBanking.create_user(sender)
      ExBanking.create_user(receiver)

      ExBanking.deposit(sender, 100, "rub")
      assert {:ok, 50, 50} == ExBanking.send(sender, receiver, 50, "rub")

    end
  end

  describe "#send/4 with valid params and existing recipient balance" do
    test "returns {:ok, from_balance, to_balance}" do
      sender = random_string(16)
      receiver = random_string(16)

      ExBanking.create_user(sender)
      ExBanking.create_user(receiver)

      ExBanking.deposit(sender, 100, "rub")
      ExBanking.deposit(receiver, 100, "rub")
      assert {:ok, 50, 150} == ExBanking.send(sender, receiver, 50, "rub")
    end
  end

  describe "#send/4 with non-existing sender" do
    test "returns {:error, sender_does_not_exist}", %{user: user} do
      ExBanking.create_user(user)

      assert {:error, :sender_does_not_exist} == ExBanking.send("some_user", user, 100, "rub")
    end
  end

  describe "#send/4 with invalid sender" do
    test "returns {:error, wrong_arguments}", %{user: user} do
      wrong_arguments = [nil, ["list"], %{}]

      for arg <- wrong_arguments do
        assert {:error, :wrong_arguments} == ExBanking.send(arg, user, 100, "rub")
      end
    end
  end

  describe "#send/4 with non-existing receiver" do
    test "return {:error, receiver_does_not_exist}", %{user: user} do
      ExBanking.create_user(user)

      assert {:error, :receiver_does_not_exist} == ExBanking.send(user, "some_user", 100, "rub")
    end
  end

  describe "#send/4 with invalid receiver" do
    test "returns {:error, wrong_arguments}", %{user: user} do

      wrong_arguments = [nil, ["list"], %{}]

      for arg <- wrong_arguments do
        assert {:error, :wrong_arguments} == ExBanking.send(user, arg, 100, "rub")
      end
    end
  end

  defp random_string(length) do
  :crypto.strong_rand_bytes(length) |> Base.url_encode64 |> binary_part(0, length)
  end
end
