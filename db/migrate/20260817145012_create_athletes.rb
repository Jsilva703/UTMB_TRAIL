class CreateAthletes < ActiveRecord::Migration[6.1]
  def change
    create_table :athletes do |t|
      t.string :name, null: false
      t.string :status, null: false, default: "active"

      t.timestamps
    end

    add_index :athletes, :status
  end
end
