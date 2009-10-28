ActiveRecord::Schema.define(:version => 0) do
  create_table :users, :force => true do |t| 
    t.string :login, :null => false
  end 
end

ActiveRecord::Schema.define(:version => 0) do
  create_table :documents, :force => true do |t| 
    t.string :name, :null => false
    t.text :content, :null => true
  end 
end
