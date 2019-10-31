class CreateProducts < ActiveRecord::Migration[5.2]
  def change
    create_table :products do |t|
      t.string :title
      t.text :desc
      t.string :image

      t.timestamps
    end
  end
end
