cups Cookbook
=============
Installs the cups package, if needed, starts the cups service, and configures printers on target systems.

Attributes
----------

#### cups::default
<table>
  <tr>
    <th>Key</th>
    <th>Type</th>
    <th>Description</th>
    <th>Default</th>
  </tr>
  <tr>
    <td><tt>['cups']['printers']</tt></td>
    <td>array</td>
    <td>List of printers to configure on the system. See example in the usage section below.</td>
    <td><tt>[]</tt></td>
  </tr>
  <tr>
    <td><tt>['cups']['systemgroups']</tt></td>
    <td>string</td>
    <td>Defines authorized system-group users in /etc/cups/cupsd.conf file.</td>
    <td><tt>sys root</tt></td>
  </tr>
  <tr>
    <td><tt>['cups']['share_printers']</tt></td>
    <td>boolean</td>
    <td>Should cups share printers?</td>
    <td><tt>true</tt></td>
  </tr>
</table>

#### cups::airprint
<table>
  <tr>
    <th>Key</th>
    <th>Type</th>
    <th>Description</th>
    <th>Default</th>
  </tr>
  <tr>
    <td><tt>['cups']['airprint_generate']['git_url']</tt></td>
    <td>string</td>
    <td>URL to the airprint file generator repo.</td>
    <td><tt>https://github.com/tjfontaine/airprint-generate.git</tt></td>
  </tr>
  <tr>
    <td><tt>['cups']['airprint_generate']['git_revision']</tt></td>
    <td>string</td>
    <td>Git repo tag/version to pull.</td>
    <td><tt>master</tt></td>
  </tr>
</table>

#### cups::default_printer
<table>
  <tr>
    <th>Key</th>
    <th>Type</th>
    <th>Description</th>
    <th>Default</th>
  </tr>
  <tr>
    <td><tt>['cups']['default_printer']</tt></td>
    <td>string</td>
    <td>Sets the system-wide default printer.</td>
    <td><tt>nil</tt></td>
  </tr>
</table>

Usage
-----
#### cups::default

Include `cups` in your node's `run_list`:

```json
{
  "name":"my_node",
  "run_list": [
    "recipe[cups]"
  ]
}
```

SAMPLE format for printer entries:
```json
"cups": {
  "printers": [
    {
      "printer1": {
        "uri": "lpd://FQDN",
        "desc": "HP LaserJet xx",
        "model": "textonly.ppd",    #textonly.ppd is set as the default by the recipe.
        "location": "Front Office"
      }
    },
    {
      "printer2": {
        "uri": "lpd://xxx.xxx.xxx.xxx"
      }
    },
    {
      "printer3": {
        "uri": "lpd://myprinter.mydomain"
      }
    }
  ]
}
```

#### cups::airprint
Configures CUPS to advertise printers via AirPrint.

#### cups::default_printer
Sets the system-wide default printer (via the `node['cups']['default_printer']` attribute).

**CAUTION** -- in its current form, this will completely overwrite the /etc/cups/lpoptions file.


Contributing
------------
1. Fork the repository on Github
2. Create a named feature branch (like `add_component_x`)
3. Write you change
4. Write tests for your change (if applicable)
5. Run the tests, ensuring they all pass
6. Submit a Pull Request using Github

License and Authors
-------------------
 Copyright 2014, Biola University

 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at

 http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
