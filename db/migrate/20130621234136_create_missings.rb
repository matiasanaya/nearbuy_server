class CreateMissings < ActiveRecord::Migration
  def change
    create_table :missings do |t|
      t.string :name
      t.string :search

      t.timestamps
    end
  end
end
