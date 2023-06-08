# frozen_string_literal: true

class CreateNewsletterUserSubscriptions < ActiveRecord::Migration[7.0]
  def change
    create_table :newsletter_user_subscriptions do |t|
      t.integer :newsletter_integration_id, null: false
      t.integer :user_id, null: false
      t.boolean :active, null: false, default: false
      t.timestamps null: false
    end

    add_index :newsletter_user_subscriptions,
              %i[user_id newsletter_integration_id],
              unique: true,
              name: "newsletter_user_subscriptions_user_id_newsletter_id_uniq"
  end
end
