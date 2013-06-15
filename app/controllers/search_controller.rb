class SearchController < ApplicationController
  def search
    render json: api_get(params[:q])
  end

  def api_get q
    # MOVER: estos require a un intializer
    require 'net/https'
    require 'uri'
    uri = URI.parse("https://api.mercadolibre.com/sites/MLA/search")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    http.ssl_version = :TLSv1
    http.start { |agent| p agent.get("#{uri.path}?q=#{q}").read_body }
  end
end
