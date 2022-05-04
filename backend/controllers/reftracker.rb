class ArchivesSpaceService < Sinatra::Base

  Endpoint.get('/plugins/reftracker/offers')
    .description("Get a list of offers that are ready to import from RefTracker")
    .params()
    .permissions([])
    .returns([200, "[offers]"]) \
  do
    RefTrackerClient.closed_questions
  end

  Endpoint.get('/plugins/reftracker/question/:qno')
    .description("Get a question from RefTracker")
    .params(['qno', String, 'The question number to get'])
    .permissions([])
    .returns([200, "question"]) \
  do
    RefTrackerClient.get_question(params[:qno])
  end

  Endpoint.post('/plugins/reftracker/import/:qno')
    .description("Import a question from RefTracker")
    .params(['qno', String, 'The question number to import'])
    .permissions([])
    .returns([200, "success"]) \
  do
    acc = RefTrackerMapper.map(RefTrackerClient.get_question(params[:qno]))
    # just returning the mapped accession for now
    json_response(acc.to_hash)
  end

end
