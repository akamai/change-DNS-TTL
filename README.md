change-DNS-TTL
=====================

A simple tool for changing TTL of zone records of Akamai DNS solutions via Akamai {OPEN} API.

For more information visit the [Akamai {OPEN} Developer Community](https://developer.akamai.com).

Installation
------------

This tool uses [AkamaiOPEN-edgegrid-ruby](https://github.com/akamai-open/AkamaiOPEN-edgegrid-ruby/) and [Oj](https://github.com/ohler55/oj).

* Install from rubygems

```bash
gem install akamai-edgegrid
gem install oj
```

* Install from Bundler

```bash
bundle install
```

Usage
-----

You have to get CONSUMER DOMAIN / CLIENT TOKEN / CLIENT SECRET / ACCESS TOKEN from Luna Portal (CONFIGURE -> Manage APIs) for using this tool.

Example (changing TTL of A, AAAA, MX records to 120):
```bash
./change-ttl.rb -z example.com -t 120 -d akaa-xxxxxxxxxxxxxxxxxxxxxxx -c akaa-yyyyyyyyyyyyyyyyyyyyy -s zzzzzzzzzzzzzzzz -a akaa-aaaaaaaaaaaaaaaaa -r A,AAAA,MX
```

Options:

| Option             |                                                                         |
| ------------------ | ----------------------------------------------------------------------- |
| -z ZONE            | Zone name to change TTL (ex. example.com)                               |
| -t TTL             | TTL to be set                                                           |
| -r RECORD_TYPE     | Comma separated record types (*Do not include space around commas*)     |
| -d CONSUMER_DOMAIN | Base URL will be https://[CONSUMER_DOMAIN].luna.akamaiapis.net          |
| -c CLIENT_TOKEN    | Client Token                                                            |
| -d CLIENT_SECRET   | Client Secret                                                           |
| -a ACCESS_TOKEN    | Access Token                                                            |
| -g                 | Change the records actually                                             |

When -g option is not set, no change will be made. Specify -g option to make the change actually.

Author
------

Hideki Okamoto <hokamoto@akamai.com>

License
-------

Copyright (C) 2014 Hideki Okamoto

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.