class CreateTodoPositions < ActiveRecord::Migration[7.2]
  def change
    create_table :todo_positions do |table|
      table.integer :issue_id, null: false
      table.integer :position, null: false
    end
    add_index :todo_positions, :issue_id, unique: true
  end
end
