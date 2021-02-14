require_relative "../config/environment.rb"
require 'active_support/inflector'
require 'pry'

class InteractiveRecord

    def self.table_name
        self.to_s.downcase.pluralize
    end

    def self.column_names
        DB[:conn].results_as_hash = true
    
        sql = "pragma table_info('#{table_name}')"
    
        table_info = DB[:conn].execute(sql)
        column_names = []
        table_info.each do |row|
          column_names << row["name"]
        end
        column_names.compact
      end

      def initialize(options = {})
        options.each do |property, value|
            self.send("#{property}=", value)
        end
      end

      def table_name_for_insert
        self.class.table_name
      end
  
      def col_names_for_insert
        column_names = []
        self.class.column_names.delete_if {|col| col == 'id'}.join(", ")
      end

      def values_for_insert
        values = []
        self.class.column_names.each do |col|
            values << "'#{self.send(col)}'" unless col == "id"
        end
        values.join(", ")
      end

      def save
        sql = <<-SQL
            INSERT INTO #{self.table_name_for_insert} (#{self.col_names_for_insert})
            VALUES (#{self.values_for_insert})
        SQL
        DB[:conn].execute(sql)
        @id = DB[:conn].execute("SELECT last_insert_rowid() FROM #{table_name_for_insert}")[0][0]
      end

      def self.find_by_name(name)
        sql = <<-SQL
            SELECT * FROM #{table_name} WHERE name = ?
        SQL
        DB[:conn].execute(sql, name)
      end

      def self.find_by(attr)
        attrs = attr.keys.collect(" = ?").join(", ")
        sql = <<-SQL
        SELECT * FROM #{table_name} WHERE #{attrs} = ?
        SQL
        puts sql
        DB[:conn].execute(sql, *attr.values)
      end
      
end