class ReftrackerOffersController < ApplicationController

  set_access_control "update_accession_record" => [:index, :import]

  def index
    render :locals => { :offers => JSONModel::HTTP::get_json('/plugins/reftracker/offers', :page => params['page']) }
  end

  def import
    offers = params.keys.select{|k| k.start_with?('offer_')}.map{|k| k.sub(/^offer_/, '')}
    response = JSONModel::HTTP::post_form("/repositories/#{session[:repo_id]}/reftracker/bulk_import", {'offers[]' => offers})

    if response.code == '200'
      import_result = ASUtils.json_parse(response.body)

      success = ''
      error = ''
      import_result.each do |offer|
        if offer.has_key?('errors')
          error += offer['qno'] + " failed to import:<ul>"
          offer['errors'].each{|err| error += "<li>#{err}</li>"}
          error += '</ul>'
        else
          success += offer['qno'] + " imported successfully: "
          success += helpers.link_to(offer['identifier'],
                                     {:controller => :resolver, :action => :resolve_readonly, :uri => offer['uri']})
          success += "<br/>"
        end
      end

      flash[:success] = success.html_safe unless success.empty?
      flash[:error] = error.html_safe unless error.empty?
    else
      flash[:error] = response.body
    end

    redirect_to(:controller => :reftracker_offers, :action => :index)
  end
end
