class CreateUsers < ActiveRecord::Migration[5.2]
  def change
    create_table :users do |t|
      t.string :name
      t.string :bio
      t.string :email
      t.string :password_digest
      t.string :icon_url
      t.string :header_url
      t.datetime :birthday
      
      t.timestamps
    end
  end
end
