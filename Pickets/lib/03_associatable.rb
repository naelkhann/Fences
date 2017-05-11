require_relative '02_searchable'
require 'active_support/inflector'

class AssocOptions
  attr_accessor(
    :foreign_key,
    :class_name,
    :primary_key
  )

  def model_class
    self.class_name.constantize
  end

  def table_name
    self.model_class.table_name
  end
end

class BelongsToOptions < AssocOptions
  def initialize(name, options = {})
    defaults = {
      :class_name => name.to_s.singularize.camelcase,
      :foreign_key => (name.to_s.downcase.underscore + "_id").to_sym,
      :primary_key => :id
    }
    options = defaults.merge(options)
    @name = name
    @foreign_key = options[:foreign_key]
    @primary_key = options[:primary_key]
    @class_name = options[:class_name]
  end
end

class HasManyOptions < AssocOptions
  def initialize(name, self_class_name, options = {})
    defaults = {
      :class_name => name.to_s.singularize.camelcase,
      :foreign_key => (self_class_name.downcase.underscore + "_id").to_sym,
      :primary_key => :id
    }
    options = defaults.merge(options)
    @name = name
    @self_class_name = self_class_name
    @foreign_key = options[:foreign_key]
    @primary_key = options[:primary_key]
    @class_name = options[:class_name]
  end
end

module Associatable
  def belongs_to(name, options = {})
    options[:class_name] = options[:class_name] || name.to_s.singularize.camelcase
    options = BelongsToOptions.new(name, options)

    assoc_options[name] = options

    define_method(name) do
      target_class = options.model_class
      if options.foreign_key.nil?
        foreign_key = self.send(target_class.to_s.downcase.underscore + "_id") if foreign_key.nil?
      else
        foreign_key = self.send(options.foreign_key)
      end
      target_class.where(:id => foreign_key).first
    end
  end

  def has_many(name, options = {})
    options[:class_name] = options[:class_name] || name.to_s.singularize.camelcase
    options = HasManyOptions.new(name, self.to_s,options)

    define_method(name) do
      target_class = options.model_class
      foreign_key = options.foreign_key
      target_class.where(options.foreign_key => self.id)
    end
  end

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

  def has_many_through(name, through, src)
    define_method(name) do
      through_options = self.class.assoc_options[through]
      source_options = through_options.model_class.assoc_options[src]

      source_table = source_options.class_name.underscore.pluralize
      through_table = through_options.class_name.underscore.pluralize

      own = self.id
      results = DBConnection.execute(<<-SQL, own)
        SELECT
          #{source_table}.*
        FROM
          #{through_table}
        JOIN
          #{source_table}
        ON
          #{source_table}.#{source_options.foreign_key} = #{through_table}.#{through_options.primary_key}
        WHERE
          #{through_options.foreign_key} = ?
      SQL

      source_options.model_class.parse_all(results)
    end
  end

  def assoc_options
    @assoc_options ||= {}
  end
end

class SQLObject
  extend Associatable
end
