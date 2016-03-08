class CreateCountries < ActiveRecord::Migration
  def change
    create_table :countries do |t|
      t.string :code, :null => false, :limit => 3  # ISO 3166 3-character country code
      t.string :name, :null => false

      t.timestamps null: false
      t.authorstamps :integer
    end
  end
end
