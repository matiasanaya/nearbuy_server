class City < ActiveRecord::Base
  attr_accessible :latitude, :longitude, :name, :search
  geocoded_by :search
  after_validation :geocode, :if => :search_changed?

  validates :search, :presence => true
end
