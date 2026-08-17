class CreateRaces < ActiveRecord::Migration[6.1]
  def change
    create_table :races do |t|
      t.string :name, null: false
      t.string :slug, null: false
      t.decimal :distance_km, precision: 10, scale: 3, null: false
      t.string :status, null: false, default: "active"

      t.timestamps
    end

    add_index :races, :slug, unique: true
    add_index :races, :status
  end
end
