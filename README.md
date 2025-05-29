# ArchivesSpace RefTracker Plugin

An ArchivesSpace plugin that integrates with RefTracker, supporting importing
records as Accessions.

----
Developed by Hudson Molonglo for the National Library of Australia.

&copy; 2022 Hudson Molonglo Pty Ltd.

----

## Compatibility

This plugin was developed against ArchivesSpace v3.2. Although it has not
been tested against other versions, it will probably work as expected on all
2.x and 3.x versions.


## Installation

This plugin has no special installation requirements. It has no database
migrations and no external gems.

1.  Download the latest [release](../../releases).
2.  Unpack it into `/path/to/your/archivesspace/plugins/`
3.  Add the plugin to your `config.rb` like this: `AppConfig[:plugins] << 'as_reftracker'`
4.  Add lines to the ArchivesSpace `config.rb`:

        AppConfig[:reftracker_base_url] = 'https://path/to/your/reftracker/api'

        AppConfig[:reftracker_mandatory_fields] = { Your list of ArchivesSpace equivalents for Reftracker mandatory fields to be imported }
        e.g. "accession_number_1, accession_accession_date, agent_role, agent_type, agent_contact_name, agent_name_name_order, agent_name_source, subject_source, subject_term, subject_term_type"

        AppConfig[:reftracker_search_api_key] = { Your Reftracker API key for search (set via Reftracker UI) }

        AppConfig[:reftracker_get_question_api_key] = { Your Reftracker API key for get_question (set via Reftracker UI) }
5.  Restart ArchivesSpace

To confirm installation has been successful, click to open the `Plug-ins`
dropdown in the application toolbar (top right of page). You should see a
`RefTracker Offers` option.


## Import Offers

1. Click on `Plug-ins` > `RefTracker Offers`
2. Offers with a status of `Closed successful` are shown, most recently closed first
3. Click the checkboxes next to the offers you would like to import
4. Click the `Import` button
