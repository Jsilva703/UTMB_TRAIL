class CreateAdminUsers < ActiveRecord::Migration[6.1]
  def change
    create_table :admin_users do |t|
      t.string :email, null: false
      t.string :password_digest, null: false
      t.boolean :active, null: false, default: true

      t.timestamps
    end

    add_index :admin_users, :email, unique: true
    add_index :admin_users, :active
  end
end
