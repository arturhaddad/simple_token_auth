class CreateAuthentications < ActiveRecord::Migration[5.0]
  def change
    create_table :authentications do |t|
    	# References
      t.references :authable, polymorphic: true # authenticatable would generate an index with a huge name

      # String
      t.string :client, null: false
      t.string :encrypted_access_token, null: false

      # Text
      t.text :metadata, null: true

      ###
      t.timestamps
    end
  end
end
