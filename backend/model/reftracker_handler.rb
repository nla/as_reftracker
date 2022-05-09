class RefTrackerHandler

  extend JSONModel

  def self.agent_map
    @agent_map ||= {
      'agent_person' => AgentPerson,
      'agent_corporate_entity' => AgentCorporateEntity,
      'agent_family' => AgentFamily,
    }
  end


  def self.import(qnos)
    out = []

    ASUtils.wrap(qnos).each do |qno|
      out << { :qno => qno }
      errors = []

      DB.transaction(:savepoint => true) do
        begin
          rt_question = RefTrackerClient.get_question(qno)

          subject_uris = RefTrackerMapper.map_subjects(rt_question).map{ |subj|
            JSONModel(:subject).from_hash(subj)
            Subject.ensure_exists(JSONModel(:subject).from_hash(subj), 'accession').uri
          }

          agent = RefTrackerMapper.map_agent(rt_question)
          agent_obj = self.agent_map[agent['jsonmodel_type']].ensure_exists(agent, 'accession')

          acc = RefTrackerMapper.map_accession(rt_question, agent_obj.uri, subject_uris)
          acc_obj = Accession.create_from_json(JSONModel(:accession).from_hash(acc))

          events = RefTrackerMapper.map_events(rt_question, acc_obj.uri, agent_obj.uri)
          events.each{|ev| Event.create_from_json(JSONModel(:event).from_hash(ev))}

          out.last[:uri] = acc_obj.uri
          out.last[:identifier] = acc['id_0']
        rescue => e
          errors << e.message
          raise Sequel::Rollback
        end
      end

      out.last[:errors] = errors unless errors.empty?
    end

    out
  end
end
