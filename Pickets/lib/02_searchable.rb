require_relative 'db_connection'
require_relative '01_sql_object'

module Searchable
  def where(params)
    table_name = self.table_name
    where_statement = []
    values = []
    params.each do |column, val|
      where_statement << "#{column} = ?"
      values << val
    end

    where_statement = where_statement.join(" AND ")

    found = DBConnection.execute2(<<-SQL, values)
      SELECT
        *
      FROM
        #{table_name}
      WHERE
        #{where_statement}
    SQL

    found.drop(1).map do |item|
      self.new(item)
    end
  end
end

class SQLObject
  # Mixin Searchable here...
  extend Searchable
end
