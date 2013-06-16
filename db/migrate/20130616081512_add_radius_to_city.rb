class AddRadiusToCity < ActiveRecord::Migration
  def change
    add_column :cities, :radius, :float
  end
end
