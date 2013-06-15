class CreateCities < ActiveRecord::Migration
  def change
    create_table :cities do |t|
      t.string :search
      t.float :latitude
      t.float :longitude
      t.string :name

      t.timestamps
    end
  end
end
