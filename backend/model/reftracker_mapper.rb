class RefTrackerMapper

  include JSONModel


  def self.map_events(qp, accession_uri, agent_uri)
    events = []

    # NLA no longer requires events
    # The accession_events plugin is used to create events for all new accessions
    # Leaving this here as a reminder and a placeholder in case events are needed again

    events
  end

  def self.map_subjects(qp)
    subjects = []

    terms = [
             'question_udf_cl10',
             'question_udf_cl09',
            ]


    terms.each do |term|
      if qp[term]
        subjects << {
          'source' => 'local',
          'vocabulary' => '/vocabularies/1',
          'terms' => [
                      {
                        'term' =>  qp[term],
                        'term_type' => 'topical',
                        'vocabulary' => '/vocabularies/1',
                      }
                     ]
        }
      end
    end

    subjects
  end


  def self.agent_type_map
    {
      'Person' => :agent_person,
      'Corporate entity' => :agent_corporate_entity,
      'Family' => :agent_family,
    }
  end


  def self.map_agent(qp)
    agent = {}

    # these come in as: Person, Corporate entity, Family
    raise "Offer: #{qp['question_no']} does not have an Agent type set" unless qp['client_udf_cl01']
    type = self.agent_type_map[qp['client_udf_cl01']]

    agent['jsonmodel_type'] = type

    agent['agent_contacts'] = [{}]
    agent['agent_contacts'][0]['address_1'] = qp['client_address1']
    agent['agent_contacts'][0]['address_2'] = qp['client_address2']
    agent['agent_contacts'][0]['city'] = qp['client_city']
    agent['agent_contacts'][0]['country'] = qp['client_country_id']
    agent['agent_contacts'][0]['email'] = qp['client_email']
    agent['agent_contacts'][0]['name'] = qp['client_name']
    agent['agent_contacts'][0]['post_code'] = qp['client_zipcode']
    agent['agent_contacts'][0]['region'] = qp['client_state_id']
    agent['agent_contacts'][0]['telephones'] = [{'number' => qp['client_phone']}]

    agent['names'] = [{}]
    agent['names'][0]['name_order'] = 'inverted'
    agent['names'][0]['primary_name'] = qp['client_region'] || qp['client_name']
    agent['names'][0]['sort_name'] = qp['client_region'] || qp['client_name']
    agent['names'][0]['source'] = 'local'

    agent['notes'] = []

    if qp['bib_udf_tb04']
      agent['notes'] << {
        'jsonmodel_type' => 'note_general_context',
        'label' => 'Vendor Code',
        'subnotes' => [{'jsonmodel_type' => 'note_text', 'content' => qp['bib_udf_tb04']}]
      }
    end

    if qp['bib_udf_ta03']
      agent['notes'] << {
        'jsonmodel_type' => 'note_bioghist',
        'label' => 'Biographical/Historical Notes',
        'subnotes' => [{'jsonmodel_type' => 'note_text', 'content' => qp['bib_udf_ta03']}]
      }
    end

    JSONModel::JSONModel(type).from_hash(agent)
  end

  def self.map_valuation_status(status)
    @valuation_status_map ||= {
      'Yes' => 'Valuation Required',
      'No' => 'Valuation Not Required',
      'Not sure' => 'Valuation Status Not Yet Determined',
      'Completed' => 'Valuation Complete'
    }

    @valuation_status_map[status]
  end


  def self.map_accession(qp, agent_uri, subject_uris)
    acc = {}

    acc['title'] = qp['bib_title']

    acc['id_0'] = qp['bib_udf_tb03']

    acc['accession_date'] = qp['question_closed_datetime'].split[0]

    acc['acquisition_type'] = qp['question_udf_cl03'].downcase
    acc['content_description'] = qp['question_udf_ta08'] || qp['question_text']
    acc['disposition'] = qp['bib_volume']
    acc['inventory'] = qp['bib_udf_tb02']
    acc['provenance'] = qp['bib_udf_ta01']
    acc['user_defined'] = {}
    acc['user_defined']['boolean_1'] = qp['bib_udf_cl01'] == 'New collection'
    acc['user_defined']['integer_2'] = qp['bib_callno']

    acc['user_defined']['string_2'] = qp['question_no']
    acc['user_defined']['string_3'] = qp['question_udf_tb08']
    acc['user_defined']['text_2'] = qp['bib_udf_ta02']
    acc['user_defined']['text_4'] = qp['question_udf_tb15']
    acc['user_defined']['text_5'] = qp['question_udf_ta09']
    acc['user_defined']['enum_1'] = map_valuation_status(qp['question_udf_cl18'])
    acc['user_defined']['enum_3'] = qp['question_udf_cl01']

    acc['extents'] = [{}]
    acc['extents'][0]['container_summary'] = qp['bib_udf_tb01']

    acc['extents'][0]['portion'] = 'whole'
    acc['extents'][0]['number'] = '1'
    acc['extents'][0]['extent_type'] = 'collection'


    acc['access_restrictions_note'] = qp['question_udf_ta15']

    acc['access_restrictions_note'] = self.munge(acc['access_restrictions_note'],
                                       qp['question_udf_tb06'],
                                       'SENSITIVITIES')

    acc['access_restrictions_note'] = self.munge(acc['access_restrictions_note'],
                                       qp['question_udf_ta10'],
                                       'INDIGENOUS ENGAGEMENT NOTES')

    acc['access_restrictions_note'] = self.munge(acc['access_restrictions_note'],
                                       qp['question_udf_ta12'],
                                       'LEGAL TITLE NOTES')

    acc['access_restrictions_note'] = self.munge(acc['access_restrictions_note'],
                                       qp['question_udf_ta14'],
                                       'RIGHTS MNGT NOTES')

    # processing notes
    acc['retention_rule'] = qp['question_udf_ta16']

    acc['retention_rule'] = self.munge(acc['retention_rule'],
                                       qp['bib_udf_ta04'],
                                       'STATEMENT OF SIGNIFICANCE')

    acc['retention_rule'] = self.munge(acc['retention_rule'],
                                       qp['bib_comment'],
                                       'CATALOGUING NOTES')


    acc['linked_agents'] = [{}]
    acc['linked_agents'][0]['ref'] = agent_uri
    acc['linked_agents'][0]['role'] = 'source'

    acc['subjects'] = []
    subject_uris.each{|uri| acc['subjects'] << {'ref' => uri}}

    JSONModel::JSONModel(:accession).from_hash(acc)
  end


  def self.munge(acc_val, qp_val, prefix = false)
    if qp_val
      if acc_val
        acc_val += "\n"
      else
        acc_val = ""
      end
      acc_val += "#{prefix}: " if prefix
      acc_val += qp_val
    end
    acc_val
  end

end
