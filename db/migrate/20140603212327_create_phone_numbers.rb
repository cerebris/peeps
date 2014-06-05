class CreatePhoneNumbers < ActiveRecord::Migration
  def change
    create_table :phone_numbers do |t|
      t.integer :contact_id
      t.string :name
      t.string :phone_number

      t.timestamps
    end
  end
end
