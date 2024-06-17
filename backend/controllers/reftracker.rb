class ArchivesSpaceService < Sinatra::Base

  Endpoint.get('/plugins/reftracker/offers')
    .description("Get a list of offers that are ready to import from RefTracker, or a specific offer")
    .params(['page', Integer, "Page number", :default => 1],
            ['ono', String, 'The offer number to get', :optional => true])
    .permissions([])
    .returns([200, "[offers]"]) \
  do
    begin
      json_response(RefTrackerClient.manuscript_offers(params[:page], params[:ono]))
    rescue ReftrackerAPIException => e
      json_response({:error => e.message})
    end
  end

  Endpoint.get('/plugins/reftracker/offer/:ono')
    .description("Get an offer from RefTracker")
    .params(['ono', String, 'The offer number to get'])
    .permissions([])
    .returns([200, "offer"], [400, 'API error']) \
  do
    begin
      json_response(RefTrackerClient.get_question(params[:ono]))
    rescue ReftrackerAPIException => e
      json_response({:error => e.message}, 400)
    end
  end

  Endpoint.get('/plugins/reftracker/codetable/:table')
    .description("Get a RefTracker code table")
    .params(['table', String, 'The code table to get'])
    .permissions([])
    .returns([200, "codetable"], [400, 'API error']) \
  do
    begin
      RefTrackerClient.get_codetable(params[:table])
    rescue ReftrackerAPIException => e
      json_response({:error => e.message}, 400)
    end
  end

  Endpoint.post('/repositories/:repo_id/reftracker/import/:offer')
    .description("Import an Offer from RefTracker as an Accession")
    .params(["repo_id", :repo_id],
            ['offer', String, 'The offer number to import'])
    .permissions([:update_accession_record])
    .returns([200, "success"], [400, "API error"]) \
  do
    json_response(RefTrackerHandler.import(params[:offer]))
  end

  Endpoint.post('/repositories/:repo_id/reftracker/bulk_import')
    .description("Import Offers from RefTracker as Accessions")
    .params(["repo_id", :repo_id],
            ['offers', String, 'The Offer numbers to import'])
    .permissions([:update_accession_record])
    .returns([200, "success"], [400, "API error"]) \
  do
    json_response(RefTrackerHandler.import(params[:offers]))
  end
end
