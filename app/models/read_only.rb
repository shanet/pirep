class ReadOnly < ApplicationRecord
  # This class is intended to be a singleton as read only mode is a site-wide configuration
  # option so there should only be a single record holding that the enabled flag
  private_class_method :new

  # Since this class is intended to be used in the Rails configuration this means that it will try to be loaded when the application
  # is initialized. However, in some cases (Rake tasks, tests, etc.) the database may not be connected or the table for this class
  # has not been created yet. Thus, we need to only attempt to hit the database once it's ready. Since this class a singleton that
  # means having a loader class which lazy loads anything from the database. This allows us to create the loader object when the
  # application initializes but nothing will hit the database until a method is explicitly called.
  class Loader
    def method_missing(method, ...)
      return object.send(method, ...)
    end

    def respond_to_missing?(method, include_private=false)
      return object.respond_to?(method, include_private)
    end

  private

    def object
      return @object ||= ReadOnly.instance
    end
  end

  def self.instance
    return first_or_create
  end

  def disabled?
    return !enabled?
  end

  def enable!
    return update(enabled: true)
  end

  def disable!
    return update(enabled: false)
  end
end
