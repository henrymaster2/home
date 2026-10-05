defmodule Home.Repo.Migrations.RepairLandlordOnboardingColumns do
  use Ecto.Migration

  def up do
    execute """
    ALTER TABLE landlords
      ADD COLUMN IF NOT EXISTS id_type varchar(255) DEFAULT 'National ID',
      ADD COLUMN IF NOT EXISTS id_number varchar(255),
      ADD COLUMN IF NOT EXISTS kra_pin varchar(255),
      ADD COLUMN IF NOT EXISTS id_front_url varchar(255),
      ADD COLUMN IF NOT EXISTS id_back_url varchar(255),
      ADD COLUMN IF NOT EXISTS listing_purpose varchar(255) DEFAULT 'renting',
      ADD COLUMN IF NOT EXISTS property_name varchar(255),
      ADD COLUMN IF NOT EXISTS ownership_type varchar(255) DEFAULT 'Freehold title',
      ADD COLUMN IF NOT EXISTS lr_number varchar(255),
      ADD COLUMN IF NOT EXISTS property_location varchar(255),
      ADD COLUMN IF NOT EXISTS total_units integer,
      ADD COLUMN IF NOT EXISTS ownership_doc_url varchar(255),
      ADD COLUMN IF NOT EXISTS subscription_plan varchar(255) DEFAULT 'pay_per_listing',
      ADD COLUMN IF NOT EXISTS billing_method varchar(255) DEFAULT 'M-Pesa',
      ADD COLUMN IF NOT EXISTS billing_phone varchar(255),
      ADD COLUMN IF NOT EXISTS enable_direct_payouts boolean DEFAULT false,
      ADD COLUMN IF NOT EXISTS payout_method varchar(255),
      ADD COLUMN IF NOT EXISTS payout_number varchar(255),
      ADD COLUMN IF NOT EXISTS payout_name varchar(255),
      ADD COLUMN IF NOT EXISTS kra_doc_url varchar(255)
    """
  end

  def down do
    :ok
  end
end
