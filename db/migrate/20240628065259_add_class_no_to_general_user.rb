class AddClassNoToGeneralUser < ActiveRecord::Migration[7.0]
  def change
    add_column :general_users, :banbie, :string
    add_column :general_users, :class_no, :string
  end
end
