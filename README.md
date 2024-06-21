# ArchivesSpace RefTracker Plugin

An ArchivesSpace plugin that integrates with RefTracker, supporting importing
records as Accessions.

----
Developed by Hudson Molonglo for the National Library of Australia.

&copy; 2022-2024 Hudson Molonglo Pty Ltd.

----

## Compatibility

This plugin was developed against ArchivesSpace v3.3.1. Although it has not
been tested against other versions, it will probably work as expected on all
2.x and 3.x versions.


## Installation

This plugin has no special installation requirements. It has no database
migrations and no external gems.

1.  Download the latest [release](../../releases).
2.  Unpack it into `/path/to/your/archivesspace/plugins/`
3.  Add the plugin to your `config.rb` like this: `AppConfig[:plugins] << 'as_reftracker'`
4.  Add a line to your `config.rb` like this:
        `AppConfig[:reftracker_base_url] = 'https://path/to/your/reftracker/api'`
5.  Restart ArchivesSpace

To confirm installation has been successful, click to open the `Plug-ins`
dropdown in the application toolbar (top right of page). You should see a
`RefTracker Offers` option.


## Import Offers as Accessions

1. Click on `Plug-ins` > `RefTracker Offers`
2. Offers with identifiers that are not already in AS are shown in reverse Offer Number order
3. Offers can also be found individually by Offer Number
3. Click the checkboxes next to the Offers you would like to import
4. Click the `Import` button
