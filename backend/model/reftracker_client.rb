require 'net/http'

class ReftrackerAPIException < StandardError; end

class RefTrackerClient

  unless AppConfig.has_key?(:reftracker_base_url)
    raise "Please set `AppConfig[:reftracker_base_url]` or disable as_reftracker plugin"
  end


  def self.get_question(question_no)
    resp = ASUtils.json_parse(self.get('getQuestion', {:parameters => {:key => 'question_no', :value => question_no, :format => 'json'}.to_json}))

    # if the question doesn't exist it returns this:
    #   [{"result":"No Question for these parameters   format:json  key:question_no  value:blah","status":"200"}]
    # so just going to assume if it is an array then it wasn't found - otherwise it would be a hash
    if resp.is_a? Array
      raise RecordNotFound.new("No Question for number #{question_no}")
    end

    resp
  end


  def self.closed_offers(page = 1)
    columns = [
               'question_no',
               'question_text',
               'bib_udf_tb03',
               'bib_title',
               'client_name',
               'question_closed_datetime',
              ]

    # status of 700 is 'Closed successful' found this using /codetable?table=status
    # qtype of 100 is 'Offerer service' - new requirement
    # db = 5 is a magic number from the original plugin.
    #        without it the api complains about missing a param called 'source'
    # sortby = 3 is ClosedDate
    search_params = {
      :status => '700',
      :qtype => '100',
      :db => '5',
      :sortby => '3',
      :sortorder => 'DESC',
      :columnList => columns.join('|'),
      :pagenumber => page,
      :pagesize => 20,
    }
    self.get('search', {:parameters => search_params.to_json})
  end


  def self.get(uri, params = {})
    url = URI(File.join(AppConfig[:reftracker_base_url], uri))
    url.query = URI.encode_www_form(params) unless params.empty?
    Net::HTTP.get(url)
  end
end
