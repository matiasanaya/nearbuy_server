class SearchController < ApplicationController
  def city
    if Search.find_by_id(params[:id])
      read = Rails.cache.read(params[:id])
      render :json => JSON.pretty_generate(build_city_list(read, params[:city_id]))
    else
      render :json => 'Invalid ID'
    end
  end

  def map
    if Search.find_by_id(params[:id])
      read = Rails.cache.read(params[:id])
      render :json => JSON.pretty_generate(build_map(read))
    else
      render :json => 'Invalid ID'
    end
  end

  def show
    if Search.find_by_id(params[:id])
      read = Rails.cache.read(params[:id])
      to_render = JSON.pretty_generate(read)
      render :json => to_render
    else
      render :json => 'Invalid ID'
    end
  end

  def page
    pagination_step = 20
    if Search.find_by_id(params[:id])
      read = Rails.cache.read(params[:id])
      if read.count/pagination_step < params[:page].to_i
        render :json => 'Invalid pagination index'
      else
        start = (params[:page].to_i-1) * pagination_step
        finish = start.to_i + pagination_step
        to_render = JSON.pretty_generate(read[start..finish])
        render :json => to_render
      end
    else
      render :json => 'Invalid ID'
    end
  end

  def search
    pagination_step = 20
    location = [params[:lat],params[:long]]
    cached_crawl = Rails.cache.read(params[:q])
    s = Search.where({:query => params[:q], :latitude => params[:lat], :longitude => params[:long]}).first
    if cached_crawl && s
      crawl = Rails.cache.read(s.id)
    elsif cached_crawl
      crawl = recalc_distances(location, cached_crawl)
      s = Search.create({:query => params[:q], :latitude => params[:lat], :longitude =>params[:long]})
      Rails.cache.write(s.id,crawl)
    else
      crawl = crawl_all_results(params[:q],location)
      s = Search.create({:query => params[:q], :latitude => params[:lat], :longitude =>params[:long]})
      Rails.cache.write(s.query, crawl)
      Rails.cache.write(s.id,crawl)
    end
    #FIX-ME me estoy comiendo la ultima pagina por miedo a stack overflow
    nresults = crawl.count
    to_return = { 'id' => s.id, 'page' => 0, 'npages' => nresults/pagination_step, 'results' => crawl[0..[19,nresults].min] }
    render :json => JSON.pretty_generate(to_return)
  end

  def recalc_distances location, crawl
    for result in crawl
      city_name = result['seller_address']['city']['name']
      c1 = City.find_by_name(city_name)
      begin
        result['distance_to_me'] = Geocoder::Calculations.distance_between(c1,location)
      rescue
        result['distance_to_me'] = 99999
      end
    end
    crawl
  end

  def crawl_all_results q, location
    #FIX-ME hardcoded location!
    state = 'AR-C'
    res = JSON.parse(api_get(q, state, 0))
    
    results = res['results']
    output = normalize_results location, results, output
    
    total = res['paging']['total']
    limit = res['paging']['limit']
    hard_limit = 5 #esta en paginas
    if total > limit
      (1..[total.to_i/limit.to_i,hard_limit].min).each do |i|
        results = JSON.parse(api_get(q, state, i))['results']
        output = normalize_results location, results, output  
      end
    end
    output['results'].sort_by { |obj| obj['distance_to_me'] }
  end

  def normalize_results location, results, output
    output ||= { 'id' => 'WAT', 'results' => [] }
    for result in results do
      city_name = result['seller_address']['city']['name']
      state_name = result['seller_address']['state']['name']
      country_name = result['seller_address']['country']['name']
      c1 = City.where(:search => "#{city_name}, Buenos Aires, Argentina", :name => city_name ).first_or_create
      begin
        result['distance_to_me'] = Geocoder::Calculations.distance_between(c1,location)
      rescue
        result['distance_to_me'] = 99999
      end
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
    lim = 200 #MAXIMO es 200
    limit = "&limit=#{lim}"
    off = lim * i
    offset = "&offset=#{off}"
    filters = location + limit + offset
    attrs = ['id','title','price','currency_id','buying_mode','condition','permalink','accepts_mercadopago','seller_address']
    attributes= "&attributes=#{attrs.join(',')}"
    http.start { |agent| p agent.get("#{uri.path}?q=#{URI.escape(q)}#{filters}").read_body }
  end

  def build_city_list results, city_id
    name = City.find(city_id).name
    output = { 'total' => 0, 'list' => [ ] }
    for result in results do
      city_name = result['seller_address']['city']['name']
      if city_name == name
        output['list'] << result
        output['total'] += 1
      end
    end
    output
  end

  def build_map results
    output = { 'total' => 0, 'map' => [] }
    names = []
    for result in results do
      city_name = result['seller_address']['city']['name']
      c1 = City.find_by_name(city_name)
      #HARD-CODED: Filter inaccurate results
      next if c1.radius > 5
      unless names.include? city_name
        names << city_name
        output['map'] << { 'id' => c1.id , 'name' => city_name, 'latitude' => c1.latitude, 'longitude' => c1.longitude, 'radius' => c1.radius , 'count' => 1 }
      else
        output['map'][names.index(city_name)]['count'] += 1
      end
      output['total'] += 1
    end
    output
  end
end
