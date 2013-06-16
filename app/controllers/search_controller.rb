class SearchController < ApplicationController
  def show
    read = Rails.cache.read(params[:id])
    to_render = JSON.pretty_generate(read)
    render :json => to_render
  end

  def search
    s = Search.where(:query => params[:q]).last
    # binding.pry
    if s && Rails.cache.read(s.id)
      render :json => JSON.pretty_generate(Rails.cache.read(s.id))
    else
      location = [params[:lat],params[:long]]
      crawler = crawl_all_results(params[:q],location)
      search = Search.create(query:params[:q])
      to_return = { 'id' => search.id, 'results' => crawler }
      Rails.cache.write(search.id, to_return)
      render :json => JSON.pretty_generate(to_return)
    end
  end

  def crawl_all_results q, location
    state = 'AR-C'
    city = 'Capital Federal'

    res = JSON.parse(api_get(q, state, 0))
    
    results = res['results']
    output = normalize_results location, results, output
    
    total = res['paging']['total']
    limit = res['paging']['limit']
    # (1..total.to_i/limit.to_i).each do |i|
    #   results = JSON.parse(api_get(q, state, i))['results']
    #   output = normalize_results location, results, output  
    # end
    output['results'].sort_by { |obj| obj['distance_to_me'] }
  end

  def normalize_results location, results, output
    output ||= { 'id' => '1234', 'results' => [] }
    for result in results do
      city_name = result['seller_address']['city']['name']
      c1 = City.where(:search => "#{city_name}, Buenos Aires, Argentina").first_or_create
      result['distance_to_me'] = Geocoder::Calculations.distance_between(c1,location)
      output['results'] << result
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
    lim = 50 #MAXIMO es 200
    limit = "&limit=#{lim}"
    off = lim * i
    offset = "&offset=#{off}"
    filters = location + limit + offset
    attrs = ['id','title','price','currency_id','buying_mode','condition','permalink','accepts_mercadopago','seller_address']
    attributes= "&attributes=#{attrs.join(',')}"
    http.start { |agent| p agent.get("#{uri.path}?q=#{URI.escape(q)}#{filters}").read_body }
  end

  #DEPRECATED
  def old_normalize_results location, results, output
    output ||= {}
    for result in results do
      city_name = result['seller_address']['city']['name']
      c1 = City.where(:search => "#{city_name}, Buenos Aires, Argentina").first_or_create
      output[city_name] ||= { 'dist' => Geocoder::Calculations.distance_between(c1,location), :res => [] }
      output[city_name][:res] << result
    end
    output
  end
end
