require_relative '03_associatable'

module Associatable

  def has_one_through(name, through, src)
    define_method(name) do
      through_options = self.class.assoc_options[through]
      source_options = through_options.model_class.assoc_options[src]

      source_table = source_options.class_name.underscore.pluralize
      through_table = through_options.class_name.underscore.pluralize

      val = self.send(through_options.foreign_key)
      results = DBConnection.execute(<<-SQL, val)
        SELECT
          #{source_table}.*
        FROM
          #{through_table}
        JOIN
          #{source_table}
        ON
          #{through_table}.#{source_options.foreign_key} = #{source_table}.#{source_options.primary_key}
        WHERE
          #{through_table}.#{through_options.primary_key} = ?
      SQL

      source_options.model_class.parse_all(results).first
    end
  end
end
