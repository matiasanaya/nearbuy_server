class SearchController < ApplicationController
  def search
    render json: all_results(params[:q], 'AR-C')
  end

  def near_me? result
    city = 'Capital Federal'
    return result['seller_address']['city']['name'] == city
  end

  def all_results q, state
    require 'JSON'
    res = JSON.parse(api_get(q, state, 0))
    results = res['results']
    output = []
    for result in results do
      # binding.pry
      output << result if near_me?(result)
    end
    # total = res['paging']['total']
    # offset = res['paging']['offset']
    # limit = res['paging']['limit']
    # (1..1).each do |i|
    #   response = JSON.parse(api_get(q, state, i))
    #   #FIX-ME: Wrong append for JSON
    #   results << "{ 'OTHER': 'REQUEST #{i}' }"
    #   results << response['results']
    # end
    output
  end

  def api_get q, state, i
    # MOVER: estos require a un intializer
    require 'net/https'
    require 'uri'
    uri = URI.parse("https://api.mercadolibre.com/sites/MLA/search")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    http.ssl_version = :TLSv1
    location = "&state=#{state}"
    lim = 10 #MAXIMO es 200
    limit = "&limit=#{lim}"
    off = lim * i
    offset = "&offset=#{off}"
    filters = location + limit + offset
    http.start { |agent| p agent.get("#{uri.path}?q=#{URI.escape(q)}#{filters}").read_body }
  end
end
