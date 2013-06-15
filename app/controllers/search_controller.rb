class SearchController < ApplicationController
  def search
    render json: api_get(params[:q])
  end

  def near_me my_loc, q

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
    loc = 'AR-C'
    location = "&state=#{loc}"
    lim = 200 #MAXIMO es 200
    limit = "&limit=#{lim}"
    step = 0
    off = lim * step
    offset = "&offset=#{off}"
    filters = location + limit + offset
    http.start { |agent| p agent.get("#{uri.path}?q=#{URI.escape(q)}#{filters}").read_body }
  end
end
