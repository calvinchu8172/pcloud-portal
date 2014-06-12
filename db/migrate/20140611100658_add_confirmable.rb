class AddConfirmable < ActiveRecord::Migration

  def change
    remove_columns :users, :confirmation_token, :confirmed_at, :confirmation_sent_at
    add_column :users, :confirmation_token, :string
    add_column :users, :confirmed_at, :datetime
    add_column :users, :confirmation_sent_at, :datetime 
    add_index :users, :confirmation_token, :unique => true
  end
end
