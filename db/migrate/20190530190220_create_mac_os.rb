class CreateMacOs < ActiveRecord::Migration[5.2]
  def change
    create_table :mac_os do |t|
      t.string :name
      t.integer :version

      t.timestamps
    end
  end
end
