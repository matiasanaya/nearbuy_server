class SearchController < ApplicationController
  def search
    location = [params[:lat],params[:long]]
    render :json => JSON.pretty_generate(crawl_all_results(params[:q],location))
  end

  def crawl_all_results q, location
    state = 'AR-C'
    city = 'Capital Federal'

    # require 'json'
    res = JSON.parse(api_get(q, state, 0))
    
    results = res['results']
    output = {}
    output = normalize_results location, results, output
    
    total = res['paging']['total']
    limit = res['paging']['limit']
    (1..total.to_i/limit.to_i).each do |i|
      results = JSON.parse(api_get(q, state, i))['results']
      output = normalize_results location, results, output  
    end
    output.sort_by { |k, v| v['dist'] }
  end

  def normalize_results location, results, output
    output ||= {}
    for result in results do
      city_name = result['seller_address']['city']['name']
      c1 = City.where(:search => "#{city_name}, Buenos Aires, Argentina").first_or_create
      output[city_name] ||= { 'dist' => Geocoder::Calculations.distance_between(c1,location), :res => [] }
      output[city_name][:res] << result
    end
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
    lim = 200 #MAXIMO es 200
    limit = "&limit=#{lim}"
    off = lim * i
    offset = "&offset=#{off}"
    filters = location + limit + offset
    http.start { |agent| p agent.get("#{uri.path}?q=#{URI.escape(q)}#{filters}").read_body }
  end
end
