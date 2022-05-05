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

  Endpoint.post('/repositories/:repo_id/accessions/reftracker_import/:qno')
    .description("Import a question from RefTracker as an Accession")
    .params(["repo_id", :repo_id],
            ['qno', String, 'The question number to import'])
    .permissions([])
    .returns([200, "success"]) \
  do
    begin
      rt_question = RefTrackerClient.get_question(params[:qno])

      # FIXME: not handling agent yet
      agent = RefTrackerMapper.map_agent(rt_question)

      acc = RefTrackerMapper.map_accession(rt_question)

      handle_create(Accession, acc)
    rescue RecordNotFound => e
      json_response({:error => e.message}, 404)
    end
  end

end
