class CreateWikiHistories < ActiveRecord::Migration
  def change
    create_table :wiki_histories do |t|
      t.references :user, null: false, index: true
      t.references :wiki, null: false, index: true
      t.text :body
      t.timestamps
    end
  end
end
