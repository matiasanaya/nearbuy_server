class City < ActiveRecord::Base
  attr_accessible :latitude, :longitude, :name, :search, :radius
  geocoded_by :search
  after_validation :geocode, :if => :search_changed?
  after_validation :add_radius

  validates :search, :presence => true

  def add_radius
    southwest = Geocoder.search(self.search)[0].data['geometry']['bounds']['southwest']
    sw = [southwest['lat'],southwest['lng']]
    self.radius = Geocoder::Calculations.distance_between(self,sw)
  end
end
