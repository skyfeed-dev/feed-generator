# Feed Generator for @skyfeed.xyz

This repository contains all SurrealQL queries powering the @skyfeed.xyz Bluesky custom feeds.

Dart code which builds the feeds is not included *yet*, because it has a lot of hard-coded env-specific logic. But the main thing it does is run the matching SurrealQL query from `lib/queries.dart`, cache the result for a while and provide pagination.

You can run the queries yourself if you have an instance of https://github.com/skyfeed-dev/indexer running somewhere, including historical follow data. `$feeduserdid` needs to be replaced with the DID of the user visiting the feed.