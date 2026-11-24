class ApplicationRecord < ActiveRecord::Base
  # Shared model base. Rails maps its concrete subclasses to database tables.
  primary_abstract_class
end
