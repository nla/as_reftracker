class ArchivesSpaceService < Sinatra::Base

  Endpoint.get('/plugins/reftracker/offers')
    .description("Get a list of offers that are ready to import from RefTracker")
    .params(['page', Integer, "Page number", :default => 1])
    .permissions([])
    .returns([200, "[offers]"]) \
  do
    RefTrackerClient.closed_offers(params[:page])
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

      subject_uris = RefTrackerMapper.map_subjects(rt_question).map{ |subj|
        JSONModel(:subject).from_hash(subj)
        Subject.ensure_exists(JSONModel(:subject).from_hash(subj), 'accession').uri
      }

      agent = RefTrackerMapper.map_agent(rt_question)
      agent_obj = agent_map[agent['jsonmodel_type']].ensure_exists(agent, 'accession')

      acc = RefTrackerMapper.map_accession(rt_question, agent_obj.uri, subject_uris)
      acc_obj = Accession.create_from_json(JSONModel(:accession).from_hash(acc))

      events = RefTrackerMapper.map_events(rt_question, acc_obj.uri, agent_obj.uri)
      events.each{|ev| Event.create_from_json(JSONModel(:event).from_hash(ev))}

      json_response({'status' => 'Import Successful', 'uri' => acc_obj.uri})

    rescue RecordNotFound => e
      json_response({:error => e.message}, 404)
    end
  end

end
