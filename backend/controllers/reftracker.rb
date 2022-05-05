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
    .returns([200, "question"], [404, 'not found']) \
  do
    begin
      json_response(RefTrackerClient.get_question(params[:qno]))
    rescue RecordNotFound => e
      json_response({:error => e.message}, 404)
    end
  end

  Endpoint.post('/repositories/:repo_id/accessions/reftracker_import/:qno')
    .description("Import a question from RefTracker as an Accession")
    .params(["repo_id", :repo_id],
            ['qno', String, 'The question number to import'])
    .permissions([])
    .returns([200, "success"], [404, "not found"]) \
  do
    # surely someone has written a method for this
    agent_map = {
      'agent_person' => AgentPerson,
      'agent_corporate_entity' => AgentCorporateEntity,
      'agent_family' => AgentFamily,
    }

    begin
      rt_question = RefTrackerClient.get_question(params[:qno])

      subject = JSONModel(:subject).from_hash(RefTrackerMapper.map_subject(rt_question))
      subject_obj = Subject.create_from_json(subject)

      agent = RefTrackerMapper.map_agent(rt_question)
      agent_obj = agent_map[agent['jsonmodel_type']].create_from_json(agent)

      acc = RefTrackerMapper.map_accession(rt_question, agent_obj.uri, subject_obj.uri)

      handle_create(Accession, acc)
    rescue RecordNotFound => e
      json_response({:error => e.message}, 404)
    end
  end

end
