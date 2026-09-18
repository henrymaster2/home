defmodule Home.Repo.Migrations.AddSubscriptionFieldsToLandlords do
  use Ecto.Migration

  def change do
    alter table(:landlords) do
      add :subscription_plan, :string, default: "pay_per_listing"
      add :billing_method, :string, default: "M-Pesa"
      add :billing_phone, :string
      add :enable_direct_payouts, :boolean, default: false
      add :payout_method, :string
      add :payout_number, :string
      add :payout_name, :string
    end
  end
end
