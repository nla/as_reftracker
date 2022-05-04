require 'net/http'

class ReftrackerAPIException < StandardError; end

class RefTrackerClient

  unless AppConfig.has_key?(:reftracker_base_url)
    raise "Please set `AppConfig[:reftracker_base_url]` or disable as_reftracker plugin"
  end


  def self.get_question(question_no)
    self.get('getQuestion', {:parameters => {:key => 'question_no', :value => question_no, :format => 'json'}.to_json})
  end


  def self.closed_questions
    columns = ['question_no', 'question_text', 'bib_number', 'bib_title', 'client_name']

    # status of 700 is 'Closed successful'
    # db = 5 is a magic number from the original plugin.
    #        without it the api complains about missing a param called 'source'
    search_params = {
      :status => '700',
      :db => '5',
      :columnList => columns.join('|'),
    }
    self.get('search', {:parameters => search_params.to_json})
  end


  def self.get(uri, params = {})
    url = URI(File.join(AppConfig[:reftracker_base_url], uri))
    url.query = URI.encode_www_form(params) unless params.empty?
    Net::HTTP.get(url)
  end
end
