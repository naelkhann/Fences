require_relative 'db_connection'
require 'active_support/inflector'
# NB: the attr_accessor we wrote in phase 0 is NOT used in the rest
# of this project. It was only a warm up.

class SQLObject
  def self.columns
    # ...
    @columns ||= (table_name = self.table_name
    cols = []
    arr = DBConnection.execute2(<<-SQL)
      SELECT
        *
      FROM #{table_name}
    SQL

    arr.first.each do |key, val|
      cols << key.to_sym
    end

    @columns = cols
    )
  end

  def self.finalize!
    self.columns.each do |column|
      define_method(column) do
        attributes[column.to_sym]
      end

      define_method(column.to_s + "=") do |arg|
        attributes[column.to_sym] = arg
      end
    end

  end

  def self.table_name=(table_name)
    @table_name = table_name
  end

  def self.table_name
    @table_name ||= self.to_s.tableize
  end

  def self.all
    table_name = self.table_name
    arr = DBConnection.execute2(<<-SQL)
      SELECT
        *
      FROM
        #{table_name}
    SQL

    self.parse_all(arr.drop(1))
  end

  def self.parse_all(results)
    results.map do |obj|
      self.new(obj)
    end
  end

  def self.find(id)
    table_name = self.table_name
    found = DBConnection.execute(<<-SQL, id)
      SELECT
        *
      FROM
        #{table_name}
      WHERE
        id = (?)
    SQL

    return nil if found.empty?
    self.new(found.first)
  end

  def initialize(params = {})
    params.each do |column,val|
       column = column.to_sym
       raise "unknown attribute '#{column}'" unless self.class.columns.include?(column)
       send("#{column}=", val)
    end
  end

  def attributes
    @attributes ||= {}
  end

  def attribute_values
    self.class.columns.map do |column|
      send("#{column}")
    end
  end

  def insert
    col_names = self.class.columns.join(",")

    spaces = ["?"] * attribute_values.length
    spaces = spaces.join(",")
    table_name = self.class.table_name
    values = attribute_values
    DBConnection.execute(<<-SQL, values)
      INSERT INTO
        #{table_name} (#{col_names})
      VALUES
        (#{spaces})
    SQL
    self.id = DBConnection.last_insert_row_id
  end

  def update
    table_name = self.class.table_name
    values = attribute_values.drop(1)
    set_clause = self.class.columns.map { |column| "#{column} = ?"}
    set_clause = set_clause.drop(1).join(",")
    sql = DBConnection.execute(<<-SQL, values, id)
      UPDATE
        #{table_name}
      SET
        #{set_clause}
      WHERE
        id = ?
    SQL
  end

  def save
    if id.nil?
      insert
    else
      update
    end
  end
end
