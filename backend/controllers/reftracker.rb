class ArchivesSpaceService < Sinatra::Base

  Endpoint.get('/plugins/reftracker/offers')
    .description("Get a list of offers that are ready to import from RefTracker")
    .params(['page', Integer, "Page number", :default => 1])
    .permissions([])
    .returns([200, "[offers]"]) \
  do
    RefTrackerClient.closed_offers(params[:page])
  end

  Endpoint.get('/plugins/reftracker/offer/:ono')
    .description("Get an offer from RefTracker")
    .params(['ono', String, 'The offer number to get'])
    .permissions([])
    .returns([200, "offer"], [404, 'not found']) \
  do
    begin
      json_response(RefTrackerClient.get_question(params[:ono]))
    rescue RecordNotFound => e
      json_response({:error => e.message}, 404)
    end
  end

  Endpoint.get('/plugins/reftracker/codetable/:table')
    .description("Get a RefTracker code table")
    .params(['table', String, 'The code table to get'])
    .permissions([])
    .returns([200, "codetable"], [404, 'not found']) \
  do
    begin
      RefTrackerClient.get_codetable(params[:table])
    rescue RecordNotFound => e
      json_response({:error => e.message}, 404)
    end
  end

  Endpoint.post('/repositories/:repo_id/reftracker/import/:offer')
    .description("Import an Offer from RefTracker as an Accession")
    .params(["repo_id", :repo_id],
            ['offer', String, 'The offer number to import'])
    .permissions([:update_accession_record])
    .returns([200, "success"], [404, "not found"]) \
  do
    json_response(RefTrackerHandler.import(params[:offer]))
  end

  Endpoint.post('/repositories/:repo_id/reftracker/bulk_import')
    .description("Import Offers from RefTracker as Accessions")
    .params(["repo_id", :repo_id],
            ['offers', String, 'The Offer numbers to import'])
    .permissions([:update_accession_record])
    .returns([200, "success"], [404, "not found"]) \
  do
    json_response(RefTrackerHandler.import(params[:offers]))
  end
end
