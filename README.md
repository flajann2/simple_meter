# Simple Meter Benchmarking

## Operation

We read a JSON template, insert the random keys, and flume it to whatever target DB we have.
We massively fork everything, and store the results in Redis. After the fact, we read
from the Redis the results, crunch the numbers, and display them. This bit is all handled
by the simple_benchmarks gem.

There are _key.rb files that are matched to the _data.json files of the same name.
The _gun.rb files are the specific "guns" to target specific database engines. The
tokumx and mongodb guns share a lot of code in common in a library.

### Updating

Updating for the purposes of testing will consist simply of adding a
'meter_bucket' array to the document, and adding new entries to
that array. 

For key-value engines, the document will be retrived and have a new entry
appended. For engines like MongoDB or Postgres, there will be no prior retrival.
The new information will simply be added to the document in place.

In the update mode, the document is required to be on the engine's server apriori,
and so a prior run to add the documents (without the --update flag) is required.

If, during an update on an engine that requires the document to be there first,
a new document will be added instead. The metrics for that should be instrumented
seperately.
