module ActiveRecord
  # = Active Record Null Relation
  module NullRelation
    def exec_queries
      @records = []
    end

    def pluck(_column_name)
      []
    end

    def delete_all(_conditions = nil)
      0
    end

    def update_all(_updates, _conditions = nil, _options = {})
      0
    end

    def delete(_id_or_array)
      0
    end

    def size
      0
    end

    def empty?
      true
    end

    def any?
      false
    end

    def many?
      false
    end

    def to_sql
      @to_sql ||= ""
    end

    def where_values_hash
      {}
    end

    def count
      0
    end

    def calculate(_operation, _column_name, _options = {})
      nil
    end

    def exists?(_id = false)
      false
    end
  end

  module QueryMethods
    # Returns a chainable relation with zero records, specifically an
    # instance of the <tt>ActiveRecord::NullRelation</tt> class.
    #
    # The returned <tt>ActiveRecord::NullRelation</tt> inherits from Relation and implements the
    # Null Object pattern. It is an object with defined null behavior and always returns an empty
    # array of records without querying the database.
    #
    # Any subsequent condition chained to the returned relation will continue
    # generating an empty relation and will not fire any query to the database.
    #
    # Used in cases where a method or scope could return zero records but the
    # result needs to be chainable.
    #
    # For example:
    #
    #   @posts = current_user.visible_posts.where(:name => params[:name])
    #   # => the visible_posts method is expected to return a chainable Relation
    #
    #   def visible_posts
    #     case role
    #     when 'Country Manager'
    #       Post.where(:country => country)
    #     when 'Reviewer'
    #       Post.published
    #     when 'Bad User'
    #       Post.none # => returning [] instead breaks the previous code
    #     end
    #   end
    #
    def none
      extending(NullRelation)
    end
  end
end