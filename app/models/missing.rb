class Missing < ActiveRecord::Base
  attr_accessible :name, :search
  validates :search, :presence => true, :uniqueness => true
end
