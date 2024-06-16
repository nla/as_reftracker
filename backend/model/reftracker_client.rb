require 'net/http'
require 'nokogiri'

class ReftrackerAPIException < StandardError; end

class RefTrackerClient

  unless AppConfig.has_key?(:reftracker_base_url)
    raise "Please set `AppConfig[:reftracker_base_url]` or disable as_reftracker plugin"
  end


  def self.strip_markup(text)
    Nokogiri::XML.fragment(Nokogiri::XML.fragment(text).text.gsub('&', '&amp;')).text
  end


  def self.get_question(question_no)
    resp = ASUtils.json_parse(self.get('getQuestion', {:parameters => {:key => 'question_no', :value => question_no, :format => 'json'}.to_json}))

    # if the question doesn't exist it returns this:
    #   [{"result":"No Question for these parameters   format:json  key:question_no  value:blah","status":"200"}]
    # so just going to assume if it is an array then it wasn't found - otherwise it would be a hash
    if resp.is_a? Array
      raise RecordNotFound.new("No Question for number #{question_no}")
    end

    # decode and strip markup - phewee - reftracker is not being friendly here
    Hash[resp.map {|k, v| [k, strip_markup(v)]}]
  end


  def self.manuscript_offers(page = 1)
    columns = [
               'question_no',
               'question_text',
               'bib_udf_tb03',
               'bib_title',
               'client_name',
               'question_format',
               'question_update_datetime',
              ]

    # status of 700 is 'Closed successful' found this using /codetable?table=status
    # :status => '700' - not doing this any more

    # qtype of 100 is 'Offerer service' - new requirement
    # db = 5 is a magic number from the original plugin.
    #        without it the api complains about missing a param called 'source'
    # sortby = 3 is ClosedDate -- no longer using this

    # last update: qnudt - can't sort by this so qno instead
    # :sortby => '50' is question_no

    # question_format = Manuscripts
    # :qnfmid => '10' 

    search_params = {
      :qtype => '100',
      :qnfmid => '10',
      :db => '5',
      :sortby => '50',
      :sortorder => 'DESC',
      :columnList => columns.join('|'),
      :pagenumber => page,
      :pagesize => 20,
    }
    self.get('search', {:parameters => search_params.to_json})

    # here's how accession.identifier looks in the db :(
    # ["moo",null,null,null]
    # NLA only uses id_0 so this works
    offer_ids = offers.map{|offer| offer['bib_udf_tb03']}.select{|id| !id.empty?}.map{|id| '["' + id + '",null,null,null]'}.compact


    # find out which of the offer_ids already exist in AS
    found_ids = nil
    DB.open{ |db| found_ids = db[:accession].filter(:identifier => offer_ids).select(:identifier).map{|i| ASUtils.json_parse(i[:identifier]).first}}

    # then filter out the found ids, and any offers without an id
    offers.select{|offer| !offer['bib_udf_tb03'].empty? && !found_ids.include?(offer['bib_udf_tb03'])}
      .map do |offer|
      offer['question_text_stripped'] = strip_markup(offer['question_text'])
      if offer['question_text_stripped'].length > 400
        offer['short_description'] = offer['question_text_stripped'][0..400]
      end
      offer
    end
  end


  # ok now got an endpoint for codetables:
  # format is format so:
  # /plugins/reftracker/codetable/format
  # tells me that format for Manuscripts is 10
  def self.get_codetable(table)
    search_params = {
      :codetable => table,
    }
    self.get('codetable', {:parameters => search_params.to_json})
  end


  def self.get(uri, params = {})
    url = URI(File.join(AppConfig[:reftracker_base_url], uri))
    url.query = URI.encode_www_form(params) unless params.empty?
    Net::HTTP.get(url)
  end
end
