class RefTrackerMapper

  include JSONModel

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
    agent['names'][0]['primary_name'] = qp['client_region']
    agent['names'][0]['sort_name'] = qp['client_region']
    agent['names'][0]['source'] = 'local'

    agent['notes'] = [{}, {}]
    agent['notes'][0]['jsonmodel_type'] = 'note_general_context'
    agent['notes'][0]['lobel'] = 'Vendor Code'
    agent['notes'][0]['subnotes'] = [{'jsonmodel_type' => 'note_text', 'content' => qp['bib_pubname']}]
    agent['notes'][1]['jsonmodel_type'] = 'note_bioghist'
    agent['notes'][1]['lobel'] = 'Biographical/Historical Notes'
    agent['notes'][1]['subnotes'] = [{'jsonmodel_type' => 'note_text', 'content' => qp['question_udf_ta01']}]

    JSONModel::JSONModel(type).from_hash(agent)
  end


  def self.map_accession(qp, agent_uri)
    acc = {}

    acc['title'] = qp['bib_title']

    # the spreadsheet says question_udf_tb07
    # but when I edited the field in RT it turned up in bib_udf_tb03
    acc['id_0'] = qp['bib_udf_tb03']
    # acc['id_0'] = qp['question_udf_tb07']
    # acc['id_0'] = qp['bib_number']

    acc['accession_date'] = qp['question_closed_datetime'].split[0]
    acc['access_restrictions_note'] = qp['question_udf_ta15']
    acc['acquisition_type'] = qp['question_udf_cl03'].downcase
    acc['content_description'] = qp['question_udf_ta08'] || qp['question_text']
    acc['disposition'] = qp['bib_volume']
    acc['inventory'] = qp['question_udf_tb11']
    acc['provenance'] = qp['question_looked']
    acc['retention_rule'] = qp['question_udf_ta16']
    acc['user_defined'] = {}
    acc['user_defined']['boolean_1'] = qp['bib_udf_cl01'] == 'New collection'
    acc['user_defined']['integer_2'] = qp['bib_callno']

    acc['user_defined']['real_3'] = qp['bib_price_actual'].gsub(/,/, '')

    acc['user_defined']['string_2'] = qp['question_no']
    acc['user_defined']['string_3'] = qp['question_udf_tb08']
    acc['user_defined']['text_2'] = qp['question_udf_tb03']
    acc['user_defined']['text_4'] = qp['question_udf_tb15']
    acc['user_defined']['text_5'] = qp['question_udf_ta09']
    acc['user_defined']['controlled_value_1'] = qp['question_udf_cl18']
    acc['user_defined']['controlled_value_3'] = qp['question_udf_cl01']

    acc['user_defined'][''] = qp['']
    acc['user_defined'][''] = qp['']
    acc['user_defined'][''] = qp['']
    acc['user_defined'][''] = qp['']

    acc['extents'] = [{}]
    acc['extents'][0]['container_summary'] = qp['bib_udf_tb01']

    # these are required but not in the mapping spec
    # could try to parse them out of the summary :(
    acc['extents'][0]['portion'] = 'whole'
    acc['extents'][0]['number'] = '1'
    acc['extents'][0]['extent_type'] = 'volumes'


    acc['retention_rule'] = self.munge(acc['retention_rule'],
                                       qp['question_usefor'],
                                       'STATEMENT OF SIGINIFICANCE')

    acc['retention_rule'] = self.munge(acc['retention_rule'],
                                       qp['question_udf_tb06'],
                                       'SENSITIVITIES')

    acc['retention_rule'] = self.munge(acc['retention_rule'],
                                       qp['question_udf_ta10'],
                                       'INDIGENOUS ENGAGEMENT NOTES')

    acc['retention_rule'] = self.munge(acc['retention_rule'],
                                       qp['question_udf_ta12'],
                                       'LEGAL TITLE NOTES')

    acc['retention_rule'] = self.munge(acc['retention_rule'],
                                       qp['question_udf_ta14'],
                                       'RIGHTS MNGT NOTES')

    acc['retention_rule'] = self.munge(acc['retention_rule'],
                                       qp['bib_comment'],
                                       'CATALOGUING NOTES')

    acc['linked_agents'] = [{}]
    acc['linked_agents'][0]['ref'] = agent_uri
    acc['linked_agents'][0]['role'] = 'source'

    # TODO: events
    # TODO: subjects

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
