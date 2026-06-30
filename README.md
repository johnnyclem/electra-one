This file is a merged representation of the entire codebase, combined into a single document by Repomix.

<file_summary>
This section contains a summary of this file.

<purpose>
This file contains a packed representation of the entire repository's contents.
It is designed to be easily consumable by AI systems for analysis, code review,
or other automated processes.
</purpose>

<file_format>
The content is organized as follows:
1. This summary section
2. Repository information
3. Directory structure
4. Repository files (if enabled)
5. Multiple file entries, each consisting of:
  - File path as an attribute
  - Full contents of the file
</file_format>

<usage_guidelines>
- This file should be treated as read-only. Any changes should be made to the
  original repository files, not this packed version.
- When processing this file, use the file path to distinguish
  between different files in the repository.
- Be aware that this file may contain sensitive information. Handle it with
  the same level of security as you would the original repository.
</usage_guidelines>

<notes>
- Some files may have been excluded based on .gitignore rules and Repomix's configuration
- Binary files are not included in this packed representation. Please refer to the Repository Structure section for a complete list of file paths, including binary files
- Files matching patterns in .gitignore are excluded
- Files matching default ignore patterns are excluded
- Files are sorted by Git change count (files with more changes are at the bottom)
</notes>

</file_summary>

<directory_structure>
.claude/
  settings.local.json
bin/
  e1.js
lib/
  device.js
  protocol.js
  transport.js
mac/
  Sources/
    e1probe/
      main.swift
    ElectraKit/
      Device.swift
      MIDITransport.swift
      Models.swift
      PresetDocument.swift
      ProjectImport.swift
      Protocol.swift
    ElectraOneApp/
      App.swift
      AppModel.swift
      ContentView.swift
  build-app.sh
  Package.swift
  README.md
presets/
  b0_s00_Demo_Preset.json
projects/
  eventide_h9_max.eproj
scripts/
  01_hello_world.lua
  02_midi_io.lua
  03_control_manipulation.lua
  04_midi_lfo.lua
  05_sysex_patch_handler.lua
tui/
  app.mjs
  smoke.test.mjs
.gitignore
LICENSE
package.json
README.md
</directory_structure>

<files>
This section contains the contents of the repository's files.

<file path=".claude/settings.local.json">
{
  "permissions": {
    "allow": [
      "Bash(npm --version)",
      "Bash(timeout 20 node bin/e1.js ports)",
      "Bash(node bin/e1.js ports)",
      "Bash(node bin/e1.js info)",
      "Bash(node bin/e1.js scan -b 0 -n 6 -t 2500)",
      "Bash(/bin/echo hello *)",
      "Bash(/bin/pwd)",
      "Bash(/bin/ls *)",
      "Bash(/usr/bin/git status *)",
      "Bash(/bin/echo \"--- transport head ---\")",
      "Bash(/usr/bin/head -3 lib/transport.js)",
      "Bash(/bin/echo \"--- perms ---\")",
      "Bash(/bin/echo \"=== git diff bin/e1.js ===\")",
      "Bash(/usr/bin/git diff *)",
      "Bash(/usr/bin/head -40)",
      "Bash(/usr/bin/find . -path ./node_modules -prune -o -path ./.git -prune -o -type d -print -exec /bin/chmod 755 {} +)",
      "Bash(/bin/chmod 755 bin/e1.js)",
      "Bash(/bin/echo \"=== after ===\")",
      "Bash(node bin/e1.js scan -b 0 -n 6 -t 1500)",
      "Bash(/usr/bin/head -30)",
      "Bash(/bin/echo \"exit=$?\")",
      "Bash(/usr/bin/head -20)",
      "Bash(rm -f /tmp/e1test.json)",
      "Bash(node bin/e1.js pull -b 0 -s 1 -o /tmp/e1test.json)",
      "Bash(/bin/echo \"--- file size ---\")",
      "Bash(/usr/bin/wc -c /tmp/e1test.json)",
      "Bash(/bin/echo \"--- push back to slot 1 ---\")",
      "Bash(/bin/cat /private/tmp/claude-501/-Users-johnnyclem-Desktop-Repos-electra-one/e80613f0-488b-4d10-a000-7b2d424b8f55/tasks/bfgjzzl92.output)",
      "WebFetch(domain:docs.electra.one)",
      "Bash(node *)"
    ]
  }
}
</file>

<file path="presets/b0_s00_Demo_Preset.json">
{
  "version": 2,
  "name": "Demo Preset",
  "projectId": "vLm21gX6Am29Mxvmf7wn",
  "pages": [
    {
      "id": 1,
      "name": "Page 1"
    },
    {
      "id": 2,
      "name": "Page 2"
    }
  ],
  "groups": [
    {
      "id": 13,
      "pageId": 1,
      "name": "GROUP 1",
      "color": "ffffff",
      "bounds": [
        16,
        10,
        379,
        16
      ]
    },
    {
      "id": 15,
      "pageId": 1,
      "name": "GROUP 2",
      "color": "ffffff",
      "bounds": [
        408,
        10,
        379,
        16
      ]
    },
    {
      "id": 16,
      "pageId": 1,
      "name": "GROUP 3",
      "color": "ffffff",
      "bounds": [
        16,
        172,
        379,
        16
      ]
    },
    {
      "id": 17,
      "pageId": 1,
      "name": "GROUP 4",
      "color": "ffffff",
      "bounds": [
        408,
        172,
        379,
        16
      ]
    },
    {
      "id": 14,
      "pageId": 1,
      "name": "TRANSPORT",
      "color": "ffffff",
      "bounds": [
        277,
        342,
        503,
        16
      ]
    },
    {
      "id": 26,
      "pageId": 2,
      "name": "CHANNEL A",
      "color": "ffffff",
      "bounds": [
        16,
        10,
        771,
        152
      ],
      "variant": "highlighted"
    },
    {
      "id": 27,
      "pageId": 2,
      "name": "CHANNEL B",
      "color": "ffffff",
      "bounds": [
        16,
        172,
        771,
        152
      ],
      "variant": "highlighted"
    },
    {
      "id": 18,
      "pageId": 2,
      "name": "TRANSPORT",
      "color": "ffffff",
      "bounds": [
        277,
        342,
        503,
        16
      ]
    }
  ],
  "devices": [
    {
      "id": 1,
      "name": "MIDI Device 1",
      "port": 1,
      "channel": 1
    }
  ],
  "overlays": [
    {
      "id": 1,
      "items": [
        {
          "value": 0,
          "label": "Mode A"
        },
        {
          "value": 1,
          "label": "Mode B"
        },
        {
          "value": 2,
          "label": "Mode C"
        }
      ]
    }
  ],
  "controls": [
    {
      "id": 1,
      "type": "fader",
      "mode": "",
      "visible": true,
      "variant": "dial",
      "name": "CC #1",
      "color": "F49500",
      "bounds": [
        20,
        36,
        175,
        122
      ],
      "pageId": 1,
      "controlSetId": 1,
      "inputs": [
        {
          "potId": 1,
          "valueId": "value"
        }
      ],
      "values": [
        {
          "message": {
            "type": "cc7",
            "min": 0,
            "max": 127,
            "parameterNumber": 1,
            "deviceId": 1
          },
          "defaultValue": 24,
          "id": "value"
        }
      ]
    },
    {
      "id": 2,
      "type": "fader",
      "mode": "",
      "visible": true,
      "variant": "dial",
      "name": "CC #2",
      "color": "F49500",
      "bounds": [
        216,
        36,
        175,
        122
      ],
      "pageId": 1,
      "controlSetId": 1,
      "inputs": [
        {
          "potId": 2,
          "valueId": "value"
        }
      ],
      "values": [
        {
          "message": {
            "type": "cc7",
            "min": 0,
            "max": 127,
            "parameterNumber": 2,
            "deviceId": 1
          },
          "defaultValue": 80,
          "id": "value"
        }
      ]
    },
    {
      "id": 3,
      "type": "fader",
      "mode": "",
      "visible": true,
      "variant": "dial",
      "name": "CC #3",
      "color": "F49500",
      "bounds": [
        412,
        36,
        175,
        122
      ],
      "pageId": 1,
      "controlSetId": 1,
      "inputs": [
        {
          "potId": 3,
          "valueId": "value"
        }
      ],
      "values": [
        {
          "message": {
            "type": "cc7",
            "min": 0,
            "max": 127,
            "parameterNumber": 3,
            "deviceId": 1
          },
          "defaultValue": 63,
          "id": "value"
        }
      ]
    },
    {
      "id": 4,
      "type": "fader",
      "mode": "",
      "visible": true,
      "variant": "dial",
      "name": "CC #4",
      "color": "F49500",
      "bounds": [
        608,
        36,
        175,
        122
      ],
      "pageId": 1,
      "controlSetId": 1,
      "inputs": [
        {
          "potId": 4,
          "valueId": "value"
        }
      ],
      "values": [
        {
          "message": {
            "type": "cc7",
            "min": 0,
            "max": 127,
            "parameterNumber": 4,
            "deviceId": 1
          },
          "defaultValue": 110,
          "id": "value"
        }
      ]
    },
    {
      "id": 5,
      "type": "fader",
      "mode": "",
      "visible": true,
      "variant": "dial",
      "name": "CC #5",
      "color": "529DEC",
      "bounds": [
        20,
        198,
        175,
        122
      ],
      "pageId": 1,
      "controlSetId": 1,
      "inputs": [
        {
          "potId": 5,
          "valueId": "value"
        }
      ],
      "values": [
        {
          "message": {
            "type": "cc7",
            "min": 0,
            "max": 127,
            "parameterNumber": 5,
            "deviceId": 1
          },
          "defaultValue": 120,
          "id": "value"
        }
      ]
    },
    {
      "id": 6,
      "type": "fader",
      "mode": "",
      "visible": true,
      "variant": "dial",
      "name": "CC #6",
      "color": "529DEC",
      "bounds": [
        216,
        198,
        175,
        122
      ],
      "pageId": 1,
      "controlSetId": 1,
      "inputs": [
        {
          "potId": 6,
          "valueId": "value"
        }
      ],
      "values": [
        {
          "message": {
            "type": "cc7",
            "min": 0,
            "max": 127,
            "parameterNumber": 6,
            "deviceId": 1
          },
          "defaultValue": 56,
          "id": "value"
        }
      ]
    },
    {
      "id": 7,
      "type": "fader",
      "mode": "",
      "visible": true,
      "variant": "dial",
      "name": "CC #7",
      "color": "529DEC",
      "bounds": [
        412,
        198,
        175,
        122
      ],
      "pageId": 1,
      "controlSetId": 1,
      "inputs": [
        {
          "potId": 7,
          "valueId": "value"
        }
      ],
      "values": [
        {
          "message": {
            "type": "cc7",
            "min": 0,
            "max": 127,
            "parameterNumber": 7,
            "deviceId": 1
          },
          "defaultValue": 20,
          "id": "value"
        }
      ]
    },
    {
      "id": 8,
      "type": "fader",
      "mode": "",
      "visible": true,
      "variant": "dial",
      "name": "CC #8",
      "color": "529DEC",
      "bounds": [
        608,
        198,
        175,
        122
      ],
      "pageId": 1,
      "controlSetId": 1,
      "inputs": [
        {
          "potId": 8,
          "valueId": "value"
        }
      ],
      "values": [
        {
          "message": {
            "type": "cc7",
            "min": 0,
            "max": 127,
            "parameterNumber": 8,
            "deviceId": 1
          },
          "defaultValue": 127,
          "id": "value"
        }
      ]
    },
    {
      "id": 9,
      "type": "pad",
      "mode": "momentary",
      "visible": true,
      "name": "START",
      "color": "ffffff",
      "bounds": [
        277,
        363,
        117,
        51
      ],
      "pageId": 1,
      "controlSetId": 1,
      "inputs": [
        {
          "potId": 9,
          "valueId": "value"
        }
      ],
      "values": [
        {
          "message": {
            "type": "start",
            "deviceId": 1
          },
          "id": "value"
        }
      ]
    },
    {
      "id": 10,
      "type": "pad",
      "mode": "momentary",
      "visible": true,
      "name": "STOP",
      "color": "ffffff",
      "bounds": [
        407,
        363,
        117,
        51
      ],
      "pageId": 1,
      "controlSetId": 1,
      "inputs": [
        {
          "potId": 10,
          "valueId": "value"
        }
      ],
      "values": [
        {
          "message": {
            "type": "stop",
            "deviceId": 1
          },
          "id": "value"
        }
      ]
    },
    {
      "id": 11,
      "type": "pad",
      "mode": "momentary",
      "visible": true,
      "name": "REWIND",
      "color": "ffffff",
      "bounds": [
        537,
        363,
        117,
        51
      ],
      "pageId": 1,
      "controlSetId": 1,
      "inputs": [
        {
          "potId": 11,
          "valueId": "value"
        }
      ],
      "values": [
        {
          "message": {
            "type": "cc7",
            "deviceId": 1,
            "parameterNumber": 11,
            "onValue": 0
          },
          "defaultValue": "off",
          "id": "value"
        }
      ]
    },
    {
      "id": 12,
      "type": "list",
      "visible": true,
      "variant": "valueOnly",
      "name": "",
      "color": "ffffff",
      "bounds": [
        667,
        363,
        117,
        51
      ],
      "pageId": 1,
      "controlSetId": 1,
      "inputs": [
        {
          "potId": 12,
          "valueId": "value"
        }
      ],
      "values": [
        {
          "message": {
            "type": "cc7",
            "parameterNumber": 12,
            "deviceId": 1
          },
          "overlayId": 1,
          "id": "value"
        }
      ]
    },
    {
      "id": 23,
      "type": "fader",
      "mode": "",
      "visible": true,
      "variant": "dial",
      "name": "DIAL",
      "color": "FC0009",
      "bounds": [
        20,
        36,
        175,
        122
      ],
      "pageId": 2,
      "controlSetId": 1,
      "inputs": [
        {
          "potId": 1,
          "valueId": "value"
        }
      ],
      "values": [
        {
          "message": {
            "type": "cc7",
            "min": 0,
            "max": 127,
            "parameterNumber": 26,
            "deviceId": 1
          },
          "defaultValue": 64,
          "id": "value"
        }
      ]
    },
    {
      "id": 24,
      "type": "fader",
      "mode": "",
      "visible": true,
      "variant": "dial",
      "name": "DIAL",
      "color": "FC0009",
      "bounds": [
        216,
        36,
        175,
        122
      ],
      "pageId": 2,
      "controlSetId": 1,
      "inputs": [
        {
          "potId": 2,
          "valueId": "value"
        }
      ],
      "values": [
        {
          "message": {
            "type": "cc7",
            "min": 0,
            "max": 127,
            "parameterNumber": 27,
            "deviceId": 1
          },
          "defaultValue": 32,
          "id": "value"
        }
      ]
    },
    {
      "id": 25,
      "type": "fader",
      "mode": "",
      "visible": true,
      "variant": "dial",
      "name": "DIAL",
      "color": "FC0009",
      "bounds": [
        412,
        36,
        175,
        122
      ],
      "pageId": 2,
      "controlSetId": 1,
      "inputs": [
        {
          "potId": 3,
          "valueId": "value"
        }
      ],
      "values": [
        {
          "message": {
            "type": "cc7",
            "min": 0,
            "max": 127,
            "parameterNumber": 28,
            "deviceId": 1
          },
          "defaultValue": 96,
          "id": "value"
        }
      ]
    },
    {
      "id": 28,
      "type": "fader",
      "mode": "",
      "visible": true,
      "variant": "dial",
      "name": "DIAL",
      "color": "FC0009",
      "bounds": [
        608,
        36,
        175,
        122
      ],
      "pageId": 2,
      "controlSetId": 1,
      "inputs": [
        {
          "potId": 4,
          "valueId": "value"
        }
      ],
      "values": [
        {
          "message": {
            "type": "cc7",
            "min": 0,
            "max": 127,
            "parameterNumber": 29,
            "deviceId": 1
          },
          "defaultValue": 127,
          "id": "value"
        }
      ]
    },
    {
      "id": 29,
      "type": "fader",
      "mode": "",
      "visible": true,
      "variant": "dial",
      "name": "DIAL",
      "color": "E4660E",
      "bounds": [
        20,
        198,
        175,
        122
      ],
      "pageId": 2,
      "controlSetId": 1,
      "inputs": [
        {
          "potId": 5,
          "valueId": "value"
        }
      ],
      "values": [
        {
          "message": {
            "type": "cc7",
            "min": 0,
            "max": 127,
            "parameterNumber": 30,
            "deviceId": 1
          },
          "defaultValue": 56,
          "id": "value"
        }
      ]
    },
    {
      "id": 30,
      "type": "fader",
      "mode": "",
      "visible": true,
      "variant": "dial",
      "name": "DIAL",
      "color": "E4660E",
      "bounds": [
        216,
        198,
        175,
        122
      ],
      "pageId": 2,
      "controlSetId": 1,
      "inputs": [
        {
          "potId": 6,
          "valueId": "value"
        }
      ],
      "values": [
        {
          "message": {
            "type": "cc7",
            "min": 0,
            "max": 127,
            "parameterNumber": 31,
            "deviceId": 1
          },
          "defaultValue": 80,
          "id": "value"
        }
      ]
    },
    {
      "id": 31,
      "type": "fader",
      "mode": "",
      "visible": true,
      "variant": "dial",
      "name": "DIAL",
      "color": "E4660E",
      "bounds": [
        412,
        198,
        175,
        122
      ],
      "pageId": 2,
      "controlSetId": 1,
      "inputs": [
        {
          "potId": 7,
          "valueId": "value"
        }
      ],
      "values": [
        {
          "message": {
            "type": "cc7",
            "min": 0,
            "max": 127,
            "parameterNumber": 32,
            "deviceId": 1
          },
          "defaultValue": 110,
          "id": "value"
        }
      ]
    },
    {
      "id": 32,
      "type": "fader",
      "mode": "",
      "visible": true,
      "variant": "dial",
      "name": "DIAL",
      "color": "E4660E",
      "bounds": [
        608,
        198,
        175,
        122
      ],
      "pageId": 2,
      "controlSetId": 1,
      "inputs": [
        {
          "potId": 8,
          "valueId": "value"
        }
      ],
      "values": [
        {
          "message": {
            "type": "cc7",
            "min": 0,
            "max": 127,
            "parameterNumber": 33,
            "deviceId": 1
          },
          "defaultValue": 16,
          "id": "value"
        }
      ]
    },
    {
      "id": 19,
      "type": "pad",
      "mode": "momentary",
      "visible": true,
      "name": "START",
      "color": "ffffff",
      "bounds": [
        277,
        363,
        117,
        51
      ],
      "pageId": 2,
      "controlSetId": 1,
      "inputs": [
        {
          "potId": 9,
          "valueId": "value"
        }
      ],
      "values": [
        {
          "message": {
            "type": "start",
            "deviceId": 1
          },
          "id": "value"
        }
      ]
    },
    {
      "id": 20,
      "type": "pad",
      "mode": "momentary",
      "visible": true,
      "name": "STOP",
      "color": "ffffff",
      "bounds": [
        407,
        363,
        117,
        51
      ],
      "pageId": 2,
      "controlSetId": 1,
      "inputs": [
        {
          "potId": 10,
          "valueId": "value"
        }
      ],
      "values": [
        {
          "message": {
            "type": "stop",
            "deviceId": 1
          },
          "id": "value"
        }
      ]
    },
    {
      "id": 21,
      "type": "pad",
      "mode": "momentary",
      "visible": true,
      "name": "REWIND",
      "color": "ffffff",
      "bounds": [
        537,
        363,
        117,
        51
      ],
      "pageId": 2,
      "controlSetId": 1,
      "inputs": [
        {
          "potId": 11,
          "valueId": "value"
        }
      ],
      "values": [
        {
          "message": {
            "type": "cc7",
            "deviceId": 1,
            "parameterNumber": 11,
            "onValue": 0
          },
          "defaultValue": "off",
          "id": "value"
        }
      ]
    },
    {
      "id": 22,
      "type": "list",
      "visible": true,
      "variant": "valueOnly",
      "name": "",
      "color": "ffffff",
      "bounds": [
        667,
        363,
        117,
        51
      ],
      "pageId": 2,
      "controlSetId": 1,
      "inputs": [
        {
          "potId": 12,
          "valueId": "value"
        }
      ],
      "values": [
        {
          "message": {
            "type": "cc7",
            "parameterNumber": 12,
            "deviceId": 1
          },
          "overlayId": 1,
          "id": "value"
        }
      ]
    }
  ]
}
</file>

<file path="projects/eventide_h9_max.eproj">
{"schemaVersion":2,"id":"747SKx4sVWVhVRJSVmcW","name":"EVENTIDE H9 MAX","description":"This is built to interact with the Factory Presets v3 on the H9 Max. \n\nSelect Algorithm>Effect>Preset\n\n[H9 Factory Presets List](https://downloads.eventide.com/audio/manuals/H9%20Max%20Factory%20Presets.pdf)\n\n[H9 Factory Presets v3](https://www.eventideaudio.com/downloads/h9-max-factory-preset-list-v3)","lua":"\r\nlocal listAlgo = \r\n{\r\n    {value = 0, label = \"Space\"},\r\n    {value = 1, label = \"Pitchfactor\"},\r\n    {value = 2, label = \"Timefactor\"},\r\n    {value = 3, label = \"Modfactor\"},\r\n    {value = 4, label = \"H9\"}\r\n}\r\noverlays.create(100, listAlgo)\r\n\r\nlocal controlAlgo = controls.get(13)\r\nlocal valueAlgo = controlAlgo:getValue()\r\nvalueAlgo:setOverlayId(100)\r\n\r\n\r\nlocal listSpaceFx = \r\n{\r\n    {value = 0, label = \"Hall\"},\r\n    {value = 1, label = \"Room\"},\r\n    {value = 2, label = \"Plate\"},\r\n    {value = 3, label = \"Spring\"},\r\n    {value = 4, label = \"DualVerb\"},\r\n    {value = 5, label = \"Reverse Reverb\"},\r\n    {value = 6, label = \"BlackHole\"},\r\n    {value = 7, label = \"MangledVerb\"},\r\n    {value = 8, label = \"TremoloVerb\"},\r\n    {value = 9, label = \"Shimmer\"},\r\n    {value = 50, label = \"ModEchoVerb\"},\r\n    {value = 51, label = \"DynaVerb\"}   \r\n}\r\noverlays.create(101, listSpaceFx)\r\n\r\nlocal listPitchFactorFx = \r\n{\r\n    {value = 10, label = \"Diatonic\"},\r\n    {value = 11, label = \"Quadravox\"},\r\n    {value = 12, label = \"HarModulator\"},\r\n    {value = 13, label = \"MicroPitch\"},\r\n    {value = 14, label = \"H910/H949\"},\r\n    {value = 15, label = \"PitchFlex\"},\r\n    {value = 16, label = \"Octaver\"},\r\n    {value = 17, label = \"Crystals\"},\r\n    {value = 18, label = \"Harpeggiator\"},\r\n    {value = 19, label = \"Synthonizer\"}\r\n}\r\noverlays.create(102, listPitchFactorFx)\r\n\r\nlocal listTimeFactorFx = \r\n{\r\n    {value = 20, label = \"Digital Delay\"},\r\n    {value = 21, label = \"Vintage Delay\"},\r\n    {value = 22, label = \"Tape Echo\"},\r\n    {value = 23, label = \"Mod Delay\"},\r\n    {value = 24, label = \"Ducked Delay\"},\r\n    {value = 25, label = \"Band Delay\"},\r\n    {value = 26, label = \"Filter Pong Delay\"},\r\n    {value = 27, label = \"MultiTap\"},\r\n    {value = 28, label = \"Reverse\"},\r\n    {value = 29, label = \"Looper\"}\r\n}\r\noverlays.create(103, listTimeFactorFx)\r\n\r\nlocal listModFactorFx = \r\n{\r\n    {value = 30, label = \"Chorus\"},\r\n    {value = 31, label = \"Phaser\"},\r\n    {value = 32, label = \"Q-Wah\"},\r\n    {value = 33, label = \"Flanger\"},\r\n    {value = 34, label = \"ModFilter\"},\r\n    {value = 35, label = \"Rotary\"},\r\n    {value = 36, label = \"TremoPan\"},\r\n    {value = 37, label = \"Vibrato\"},\r\n    {value = 38, label = \"Undulator\"},\r\n    {value = 39, label = \"RingMod\"}\r\n}\r\noverlays.create(104, listModFactorFx)\r\n\r\n\r\nlocal listH9Fx = \r\n{\r\n    {value = 40, label = \"Ultra Tap\"},\r\n    {value = 41, label = \"Resonator\"},\r\n    {value = 42, label = \"EQ Compressor\"},\r\n    {value = 43, label = \"CrushStation\"},\r\n    {value = 44, label = \"SpaceTime\"},\r\n    {value = 45, label = \"Sculpt\"},\r\n    {value = 46, label = \"PitchFuzz\"},\r\n    {value = 47, label = \"HotSawz\"},\r\n    {value = 48, label = \"Harmadillo\"},\r\n    {value = 49, label = \"TriceraChorus\"}\r\n}\r\noverlays.create(105, listH9Fx)\r\n\r\nfunction toggleAlgo(valueObject, value)\r\n    local control = valueObject:getControl()\r\n    local controlFx = controls.get(14)\r\n    local valueFx = controlFx:getValue()\r\n\r\n    local controlParam1 = controls.get(3)\r\n    local controlParam2 = controls.get(4)\r\n    local controlParam3 = controls.get(5)\r\n    local controlParam4 = controls.get(6)\r\n    local controlParam5 = controls.get(7)\r\n    local controlParam6 = controls.get(8)\r\n    local controlParam7 = controls.get(9)\r\n    local controlParam8 = controls.get(10)\r\n    local controlParam9 = controls.get(11)\r\n    local controlParam10= controls.get(12)\r\n\r\n    local valueParam1 = controlParam1:getValue()\r\n    local valueParam2 = controlParam2:getValue()\r\n    local valueParam3 = controlParam3:getValue()\r\n    local valueParam4 = controlParam4:getValue()\r\n    local valueParam5 = controlParam5:getValue()\r\n    local valueParam6 = controlParam6:getValue()\r\n    local valueParam7 = controlParam7:getValue()\r\n    local valueParam8 = controlParam8:getValue()\r\n    local valueParam9 = controlParam9:getValue()\r\n    local valueParam10 = controlParam10:getValue()\r\n\r\n    if(valueToggle == 0) then --Space\r\n        control:setColor(PURPLE)\r\n        controlFx:setColor(PURPLE)\r\n\r\n        controlParam1:setColor(PURPLE)\r\n        controlParam2:setColor(PURPLE)\r\n        controlParam3:setColor(PURPLE)\r\n        controlParam4:setColor(PURPLE)\r\n        controlParam5:setColor(PURPLE)\r\n        controlParam6:setColor(PURPLE)\r\n        controlParam7:setColor(PURPLE)\r\n        controlParam8:setColor(PURPLE)\r\n        controlParam9:setColor(PURPLE)\r\n        controlParam10:setColor(PURPLE)        \r\n\r\n        valueFx:setOverlayId(101)\r\n    elseif(value == 1) then --TimeFactor\r\n        control:setColor(BLUE)\r\n        controlFx:setColor(BLUE)\r\n        controlParam1:setColor(BLUE)\r\n        controlParam2:setColor(BLUE)\r\n        controlParam3:setColor(BLUE)\r\n        controlParam4:setColor(BLUE)\r\n        controlParam5:setColor(BLUE)\r\n        controlParam6:setColor(BLUE)\r\n        controlParam7:setColor(BLUE)\r\n        controlParam8:setColor(BLUE)\r\n        controlParam9:setColor(BLUE)\r\n        controlParam10:setColor(BLUE)        \r\n        valueFx:setOverlayId(102)\r\n    elseif(value == 2) then --PitchFactor\r\n        control:setColor(RED)\r\n        controlFx:setColor(RED)\r\n        controlParam1:setColor(RED)\r\n        controlParam2:setColor(RED)\r\n        controlParam3:setColor(RED)\r\n        controlParam4:setColor(RED)\r\n        controlParam5:setColor(RED)\r\n        controlParam6:setColor(RED)\r\n        controlParam7:setColor(RED)\r\n        controlParam8:setColor(RED)\r\n        controlParam9:setColor(RED)\r\n        controlParam10:setColor(RED)     \r\n        valueFx:setOverlayId(103)\r\n    elseif(value == 3) then --ModFactor\r\n        control:setColor(GREEN)\r\n        controlFx:setColor(GREEN)\r\n        controlParam1:setColor(GREEN)\r\n        controlParam2:setColor(GREEN)\r\n        controlParam3:setColor(GREEN)\r\n        controlParam4:setColor(GREEN)\r\n        controlParam5:setColor(GREEN)\r\n        controlParam6:setColor(GREEN)\r\n        controlParam7:setColor(GREEN)\r\n        controlParam8:setColor(GREEN)\r\n        controlParam9:setColor(GREEN)\r\n        controlParam10:setColor(GREEN)   \r\n        valueFx:setOverlayId(104)\r\n    elseif(value == 4) then --H9\r\n        control:setColor(WHITE)\r\n        controlFx:setColor(WHITE)\r\n        controlParam1:setColor(WHITE)\r\n        controlParam2:setColor(WHITE)\r\n        controlParam3:setColor(WHITE)\r\n        controlParam4:setColor(WHITE)\r\n        controlParam5:setColor(WHITE)\r\n        controlParam6:setColor(WHITE)\r\n        controlParam7:setColor(WHITE)\r\n        controlParam8:setColor(WHITE)\r\n        controlParam9:setColor(WHITE)\r\n        controlParam10:setColor(WHITE)   \r\n        valueFx:setOverlayId(105)\r\n    else\r\n        control:setColor(WHITE)\r\n        valueFx:setOverlayId(101)\r\n    end\r\nend\r\n\r\n\r\n\r\n--BEGIN EFFECTS TO PRELIST MAPPING\r\nlocal listBandDelay = {{value = 72, label = \"GUITARS IN SPACE\"}, {value = 30, label = \"REGGAE WAHDELAY\"}}\r\noverlays.create(200, listBandDelay)\r\nlocal listBlackhole = {\r\n    {value = 12, label = \"BLACKHOLE\"},\r\n    {value = 41, label = \"DARKMATTER\"},\r\n    {value = 45, label = \"PULSAR II\"}\r\n}\r\noverlays.create(201, listBlackhole)\r\nlocal listChorus = {{value = 56, label = \"LIQUID SWEETENER\"}}\r\noverlays.create(202, listChorus)\r\nlocal listCrushStation = {{value = 57, label = \"BOTTOM FEEDER\"}, {value = 9, label = \"METAL\"}}\r\noverlays.create(203, listCrushStation)\r\nlocal listCrystals = {{value = 28, label = \"CLASSIC CRYSTALS\"}, {value = 55, label = \"FROM A BAD DREAM\"}}\r\noverlays.create(204, listCrystals)\r\nlocal listDiatonic = {\r\n    {value = 6, label = \"EMAJ 3RD+\"},\r\n    {value = 11, label = \"STORYTELLER\"},\r\n    {value = 85, label = \"TRY EEEEEEEE\"}\r\n}\r\noverlays.create(205, listDiatonic)\r\nlocal listDigitalDelay = {\r\n    {value = 0, label = \"DDLY\"},\r\n    {value = 92, label = \"EVPREMIX\"},\r\n    {value = 88, label = \"PRISTINE DIGITAL DELAY\"}\r\n}\r\noverlays.create(206, listDigitalDelay)\r\nlocal listDualVerb = {{value = 26, label = \"DUALVERB\"}}\r\noverlays.create(207, listDualVerb)\r\nlocal listDuckedDelay = {{value = 77, label = \"COUNTRY COMRESSOR\"}}\r\noverlays.create(208, listDuckedDelay)\r\nlocal listEQCompressor = {{value = 52, label = \"SWEET HOME\"}}\r\noverlays.create(209, listEQCompressor)\r\nlocal listFilterPong = {{value = 91, label = \"GOOEYFILTEROPONG\"}, {value = 73, label = \"SCIENCE MUSEUM\"}}\r\noverlays.create(210, listFilterPong)\r\nlocal listFlanger = {{value = 58, label = \"LONG FLYBY\"}}\r\noverlays.create(211, listFlanger)\r\nlocal listH910H949 = {\r\n    {value = 49, label = \"FAT H910\"},\r\n    {value = 67, label = \"INSANITY BUILD\"},\r\n    {value = 40, label = \"POWERCHORD\"},\r\n    {value = 76, label = \"RISING SWIM\"},\r\n    {value = 2, label = \"SLAP\"}\r\n}\r\noverlays.create(212, listH910H949)\r\nlocal listHall = {\r\n    {value = 50, label = \"CARNEGIE HALL\"},\r\n    {value = 23, label = \"CORRIDORS\"},\r\n    {value = 32, label = \"DARK CAVE\"},\r\n    {value = 68, label = \"PHANTOM VERB\"}\r\n}\r\noverlays.create(213, listHall)\r\nlocal listHarModulator = {{value = 16, label = \"ELEC12STRING ROO\"}, {value = 37, label = \"VAIBALLERINA\"}}\r\noverlays.create(214, listHarModulator)\r\nlocal listHarPeggiator = {{value = 66, label = \"MACHINES\"}}\r\noverlays.create(215, listHarPeggiator)\r\nlocal listHarmadillo = {\r\n    {value = 83, label = \"DOUBLE BANDED\"},\r\n    {value = 78, label = \"ECHO MORPH\"},\r\n    {value = 24, label = \"MASTER OF BANDS\"},\r\n    {value = 51, label = \"ONLY TAILS\"},\r\n    {value = 44, label = \"PHRIENDLY VIBE\"},\r\n    {value = 33, label = \"PLUCK FADE\"}\r\n}\r\noverlays.create(216, listHarmadillo)\r\nlocal listHotSawz = {\r\n    {value = 47, label = \"CAMINO\"},\r\n    {value = 93, label = \"FAUX HORNS\"},\r\n    {value = 31, label = \"KNIFE WALKER\"}\r\n}\r\noverlays.create(217, listHotSawz)\r\nlocal listLooper = {{value = 98, label = \"BASIC LOOPER\"}}\r\noverlays.create(218, listLooper)\r\nlocal listMangledVerb = {{value = 90, label = \"MANGLEDVERB\"}}\r\noverlays.create(219, listMangledVerb)\r\nlocal listMicroPitch = {{value = 82, label = \"H3000 MICROPITCH\"}, {value = 3, label = \"THICK\"}}\r\noverlays.create(220, listMicroPitch)\r\nlocal listModDelay = {{value = 81, label = \"EVERY LEAD YOU FAKE\"}}\r\noverlays.create(221, listModDelay)\r\nlocal listModEchoVerb = {{value = 14, label = \"MODECHOVERB\"}, {value = 74, label = \"PLANETARIUM1\"}}\r\noverlays.create(222, listModEchoVerb)\r\nlocal listMultiTap = {{value = 95, label = \"TAPOMATIC\"}}\r\noverlays.create(223, listMultiTap)\r\nlocal listPitchFuzz = {\r\n    {value = 22, label = \"3 OCTAVES\"},\r\n    {value = 71, label = \"CHORUS AND DELAY\"},\r\n    {value = 21, label = \"COPELAND\"},\r\n    {value = 17, label = \"FUZZYMASS\"}\r\n}\r\noverlays.create(224, listPitchFuzz)\r\nlocal listPlate = {{value = 89, label = \"OILDRUM\"}}\r\noverlays.create(225, listPlate)\r\nlocal listQWah = {{value = 5, label = \"AUTO WAH\"}, {value = 54, label = \"LAZYPHASYWAH\"}}\r\noverlays.create(226, listQWah)\r\nlocal listQuadravox = {{value = 94, label = \"ANTHEM\"}, {value = 43, label = \"TEENAGE WASTELAND\"}}\r\noverlays.create(227, listQuadravox)\r\nlocal listResonator = {{value = 39, label = \"ANDY WARHOL ON THE RUN\"}, {value = 70, label = \"SPELUNKING\"}}\r\noverlays.create(228, listResonator)\r\nlocal listReverse = {{value = 64, label = \"BACKWARDS RIFFS\"}}\r\noverlays.create(229, listReverse)\r\nlocal listReverseReverb = {{value = 19, label = \"GHOST PLATE\"}}\r\noverlays.create(230, listReverseReverb)\r\nlocal listRingMod = {{value = 46, label = \"ELECTRICITYRING\"}}\r\noverlays.create(231, listRingMod)\r\nlocal listRotary = {{value = 4, label = \"LESLIE\"}}\r\noverlays.create(232, listRotary)\r\nlocal listSculpt = {\r\n    {value = 8, label = \"AIRBAG\"},\r\n    {value = 63, label = \"FUNKE BIASS\"},\r\n    {value = 38, label = \"WAHCRAFT\"}\r\n}\r\noverlays.create(233, listSculpt)\r\nlocal listShimmer = {\r\n    {value = 42, label = \"HELLS GATE\"},\r\n    {value = 80, label = \"NEROS ASCENT\"},\r\n    {value = 62, label = \"QUASAR\"},\r\n    {value = 13, label = \"SHIMMER\"},\r\n    {value = 35, label = \"TOUCHED BY AN H9\"}\r\n}\r\noverlays.create(234, listShimmer)\r\nlocal listSpaceTime = {\r\n    {value = 25, label = \"EXTRATERRESTRIAL\"},\r\n    {value = 59, label = \"FAUX LESLIE\"},\r\n    {value = 18, label = \"SPACETIME\"}\r\n}\r\noverlays.create(235, listSpaceTime)\r\nlocal listSpring = {{value = 53, label = \"DELUXE\"}, {value = 7, label = \"SPRING\"}}\r\noverlays.create(236, listSpring)\r\nlocal listTapeEcho = {{value = 48, label = \"BE WOWED\"}, {value = 1, label = \"ECHO\"}, {value = 75, label = \"FLUTTERWOW\"}}\r\noverlays.create(237, listTapeEcho)\r\nlocal listTremoloPan = {{value = 69, label = \"FLUTTER TREM\"}, {value = 87, label = \"I WALK ALONE\"}}\r\noverlays.create(238, listTremoloPan)\r\n\r\n \r\nfunction togglePreset(valueObject, value)\r\n    local controlPreset = controls.get(15)\r\n    local valuePreset = controlPreset:getValue()\r\n    local controlToggle = valueObject:getMessage()\r\n    local valueToggle = controlToggle:getValue()\r\n\r\n    print(valueToggle)\r\n\r\n    local controlParam1 = controls.get(3)\r\n    local controlParam2 = controls.get(4)\r\n    local controlParam3 = controls.get(5)\r\n    local controlParam4 = controls.get(6)\r\n    local controlParam5 = controls.get(7)\r\n    local controlParam6 = controls.get(8)\r\n    local controlParam7 = controls.get(9)\r\n    local controlParam8 = controls.get(10)\r\n    local controlParam9 = controls.get(11)\r\n    local controlParam10 = controls.get(12)\r\n    print(value)\r\n    \r\n    if (valueToggle == 25) then\r\n        valuePreset:setOverlayId(200)\r\n        controlParam1:setName(\"Mix\")\r\n        controlParam2:setName(\"Delay Mix\")\r\n        controlParam3:setName(\"Delay A\")\r\n        controlParam4:setName(\"Delay B\")\r\n        controlParam5:setName(\"Feedback A\")\r\n        controlParam6:setName(\"Feedback B\")\r\n        controlParam7:setName(\"Low Band Frequency\")\r\n        controlParam8:setName(\"High Band Frequency\")\r\n        controlParam9:setName(\"Resonance\")\r\n        controlParam10:setName(\"Filter\")\r\n    elseif (valueToggle == 6) then\r\n        valuePreset:setOverlayId(201)\r\n        controlParam1:setName(\"Mix\")\r\n        controlParam2:setName(\"Gravity Mode Select\")\r\n        controlParam3:setName(\"Size\")\r\n        controlParam4:setName(\"Delay\")\r\n        controlParam5:setName(\"Low Band Shelving Level\")\r\n        controlParam6:setName(\"High Band Shelving Level\")\r\n        controlParam7:setName(\"Modulation Depth\")\r\n        controlParam8:setName(\"Modulation Rate\")\r\n        controlParam9:setName(\"Feedback\")\r\n        controlParam10:setName(\"Resonance\")\r\n    elseif (valueToggle == 30) then\r\n        valuePreset:setOverlayId(202)\r\n        controlParam1:setName(\"Mix\")\r\n        controlParam2:setName(\"Depth\")\r\n        controlParam3:setName(\"Speed\")\r\n        controlParam4:setName(\"Shape\")\r\n        controlParam5:setName(\"Filter\")\r\n        controlParam6:setName(\"Feedback\")\r\n        controlParam7:setName(\"Mod Source\")\r\n        controlParam8:setName(\"Mod Rate\")\r\n        controlParam9:setName(\"Delay\")\r\n        controlParam10:setName(\"Width\")\r\n    elseif (valueToggle == 43) then\r\n        valuePreset:setOverlayId(203)\r\n        controlParam1:setName(\"Mix\")\r\n        controlParam2:setName(\"Gain\")\r\n        controlParam3:setName(\"Sustain\")\r\n        controlParam4:setName(\"Sag\")\r\n        controlParam5:setName(\"Octave Mix\")\r\n        controlParam6:setName(\"Compressor\")\r\n        controlParam7:setName(\"Gate\")\r\n        controlParam8:setName(\"Mid Shift\")\r\n        controlParam9:setName(\"High Shift\")\r\n        controlParam10:setName(\"Low Shift\")\r\n    elseif (valueToggle == 17) then\r\n        valuePreset:setOverlayId(204)\r\n        controlParam1:setName(\"Mix\")\r\n        controlParam2:setName(\"Pitch A/B Mix\")\r\n        controlParam3:setName(\"Pitch Shift A\")\r\n        controlParam4:setName(\"Pitch Shift B\")\r\n        controlParam5:setName(\"Reverse Delay Buffer A\")\r\n        controlParam6:setName(\"Reverse Delay Buffer B\")\r\n        controlParam7:setName(\"Reverb Mix Level\")\r\n        controlParam8:setName(\"Reverb Decay Rate\")\r\n        controlParam9:setName(\"Feedback A\")\r\n        controlParam10:setName(\"Feedback B\")\r\n    elseif (valueToggle == 10) then\r\n        valuePreset:setOverlayId(205)\r\n        controlParam1:setName(\"Mix\")\r\n        controlParam2:setName(\"Pitch A/B Mix\")\r\n        controlParam3:setName(\"Pitch Shift A\")\r\n        controlParam4:setName(\"Pitch Shift B\")\r\n        controlParam5:setName(\"Delay A\")\r\n        controlParam6:setName(\"Delay B\")\r\n        controlParam7:setName(\"Key\")\r\n        controlParam8:setName(\"Scale\")\r\n        controlParam9:setName(\"Feedback A\")\r\n        controlParam10:setName(\"Feedback B\")\r\n    elseif (valueToggle == 20) then\r\n        valuePreset:setOverlayId(206)\r\n        controlParam1:setName(\"Mix\")\r\n        controlParam2:setName(\"Delay Mix\")\r\n        controlParam3:setName(\"Delay A\")\r\n        controlParam4:setName(\"Delay B\")\r\n        controlParam5:setName(\"Feedback A\")\r\n        controlParam6:setName(\"Feedback B\")\r\n        controlParam7:setName(\"Crossfade\")\r\n        controlParam8:setName(\"Modulation Depth\")\r\n        controlParam9:setName(\"Modulation Speed\")\r\n        controlParam10:setName(\"Filter\")\r\n    elseif (valueToggle == 4) then\r\n        valuePreset:setOverlayId(207)\r\n        controlParam1:setName(\"Mix\")\r\n        controlParam2:setName(\"Reverb A Decay\")\r\n        controlParam3:setName(\"Size\")\r\n        controlParam4:setName(\"Reverb A PreDelay\")\r\n        controlParam5:setName(\"Reverb A Tone Control\")\r\n        controlParam6:setName(\"Reverb B Tone Control\")\r\n        controlParam7:setName(\"Reverb B Decay\")\r\n        controlParam8:setName(\"Reverb B PreDelay\")\r\n        controlParam9:setName(\"Reverb A/B Mix\")\r\n        controlParam10:setName(\"Resonance\")\r\n    elseif (valueToggle == 24) then\r\n        valuePreset:setOverlayId(208)\r\n        controlParam1:setName(\"Mix\")\r\n        controlParam2:setName(\"Delay Mix\")\r\n        controlParam3:setName(\"Delay A\")\r\n        controlParam4:setName(\"Delay B\")\r\n        controlParam5:setName(\"Feedback A\")\r\n        controlParam6:setName(\"Feedback B\")\r\n        controlParam7:setName(\"Ducking Threshold\")\r\n        controlParam8:setName(\"Ducking Release\")\r\n        controlParam9:setName(\"Ducking Depth\")\r\n        controlParam10:setName(\"Filter\")\r\n    elseif (valueToggle == 42) then\r\n        valuePreset:setOverlayId(209)\r\n        controlParam1:setName(\"Mix\")\r\n        controlParam2:setName(\"Bass\")\r\n        controlParam3:setName(\"Mid\")\r\n        controlParam4:setName(\"Treble\")\r\n        controlParam5:setName(\"Gain\")\r\n        controlParam6:setName(\"Compressor Threshold\")\r\n        controlParam7:setName(\"Compressor Ratio\")\r\n        controlParam8:setName(\"Attack Time\")\r\n        controlParam9:setName(\"Release Time\")\r\n        controlParam10:setName(\"Output Level\")\r\n    elseif (valueToggle == 26) then\r\n        valuePreset:setOverlayId(210)\r\n        controlParam1:setName(\"Mix\")\r\n        controlParam2:setName(\"Delay Mix\")\r\n        controlParam3:setName(\"Delay A\")\r\n        controlParam4:setName(\"Delay B\")\r\n        controlParam5:setName(\"Feedback A\")\r\n        controlParam6:setName(\"Feedback B\")\r\n        controlParam7:setName(\"Filter Frequency\")\r\n        controlParam8:setName(\"Filter Resonance\")\r\n        controlParam9:setName(\"Filter Type\")\r\n        controlParam10:setName(\"Width\")\r\n    elseif (valueToggle == 33) then\r\n        valuePreset:setOverlayId(211)\r\n        controlParam1:setName(\"Mix\")\r\n        controlParam2:setName(\"Depth\")\r\n        controlParam3:setName(\"Speed\")\r\n        controlParam4:setName(\"Shape\")\r\n        controlParam5:setName(\"Resonance\")\r\n        controlParam6:setName(\"Manual\")\r\n        controlParam7:setName(\"Mod Source\")\r\n        controlParam8:setName(\"Mod Rate\")\r\n        controlParam9:setName(\"Feedback\")\r\n        controlParam10:setName(\"Width\")\r\n    elseif (valueToggle == 14) then\r\n        valuePreset:setOverlayId(212)\r\n        controlParam1:setName(\"Mix\")\r\n        controlParam2:setName(\"Pitch A/B Mix\")\r\n        controlParam3:setName(\"Pitch Shift Up A\")\r\n        controlParam4:setName(\"Pitch Shift Down B\")\r\n        controlParam5:setName(\"Delay A\")\r\n        controlParam6:setName(\"Delay B\")\r\n        controlParam7:setName(\"Splice Type\")\r\n        controlParam8:setName(\"Pitch Coarse/Fine Control\")\r\n        controlParam9:setName(\"Pitch A Feedback\")\r\n        controlParam10:setName(\"Pitch B Feedback\")\r\n    elseif (valueToggle == 0) then\r\n        valuePreset:setOverlayId(213)\r\n        controlParam1:setName(\"Mix\")\r\n        controlParam2:setName(\"Decay\")\r\n        controlParam3:setName(\"Size\")\r\n        controlParam4:setName(\"Pre Delay\")\r\n        controlParam5:setName(\"Low Band Reverb Level\")\r\n        controlParam6:setName(\"High Band Reverb Level\")\r\n        controlParam7:setName(\"Low Band Decay\")\r\n        controlParam8:setName(\"High Band Decay\")\r\n        controlParam9:setName(\"Modulation Level\")\r\n        controlParam10:setName(\"Mid Band Reverb Level\")\r\n    elseif (valueToggle == 12) then\r\n        valuePreset:setOverlayId(214)\r\n        controlParam1:setName(\"Mix\")\r\n        controlParam2:setName(\"Pitch A/B Mix\")\r\n        controlParam3:setName(\"Pitch Shift A\")\r\n        controlParam4:setName(\"Pitch Shift B\")\r\n        controlParam5:setName(\"Delay A\")\r\n        controlParam6:setName(\"Delay B\")\r\n        controlParam7:setName(\"Modulation Depth\")\r\n        controlParam8:setName(\"Modulation Rate\")\r\n        controlParam9:setName(\"Modulation Shape\")\r\n        controlParam10:setName(\"Feedback\")\r\n    elseif (valueToggle == 18) then\r\n        valuePreset:setOverlayId(215)\r\n        controlParam1:setName(\"Mix\")\r\n        controlParam2:setName(\"Arpeggiator A/B Mix\")\r\n        controlParam3:setName(\"Pitch Sequence A\")\r\n        controlParam4:setName(\"Pitch Sequence B\")\r\n        controlParam5:setName(\"Rhythm A\")\r\n        controlParam6:setName(\"Rhythm B\")\r\n        controlParam7:setName(\"Effect A\")\r\n        controlParam8:setName(\"Effect B\")\r\n        controlParam9:setName(\"Step Length\")\r\n        controlParam10:setName(\"Dynamics\")\r\n    elseif (valueToggle == 48) then\r\n        valuePreset:setOverlayId(216)\r\n        controlParam1:setName(\"Mix\")\r\n        controlParam2:setName(\"Depth\")\r\n        controlParam3:setName(\"Speed\")\r\n        controlParam4:setName(\"Shape\")\r\n        controlParam5:setName(\"Tone\")\r\n        controlParam6:setName(\"Modulation Source\")\r\n        controlParam7:setName(\"Harmonic Ratio\")\r\n        controlParam8:setName(\"Tremolo Type\")\r\n        controlParam9:setName(\"Feedback\")\r\n        controlParam10:setName(\"Width\")\r\n    elseif (valueToggle == 47) then\r\n        valuePreset:setOverlayId(217)\r\n        controlParam1:setName(\"Mix\")\r\n        controlParam2:setName(\"Filter Frequency\")\r\n        controlParam3:setName(\"Resonance\")\r\n        controlParam4:setName(\"Modulation Depth\")\r\n        controlParam5:setName(\"Modulation Rate\")\r\n        controlParam6:setName(\"Drive\")\r\n        controlParam7:setName(\"Envelope Amount\")\r\n        controlParam8:setName(\"Attack\")\r\n        controlParam9:setName(\"Decay\")\r\n        controlParam10:setName(\"Sustain\")\r\n    elseif (valueToggle == 29) then\r\n        valuePreset:setOverlayId(218)\r\n        controlParam1:setName(\"Mix\")\r\n        controlParam2:setName(\"Record Length\")\r\n        controlParam3:setName(\"Speed\")\r\n        controlParam4:setName(\"Reverse\")\r\n        controlParam5:setName(\"Overdub\")\r\n        controlParam6:setName(\"Dub Decay\")\r\n        controlParam7:setName(\"Loop Start\")\r\n        controlParam8:setName(\"Loop End\")\r\n        controlParam9:setName(\"Play Mode\")\r\n        controlParam10:setName(\"Fade\")\r\n    elseif (valueToggle == 7) then\r\n        valuePreset:setOverlayId(219)\r\n        controlParam1:setName(\"Mix\")\r\n        controlParam2:setName(\"Decay\")\r\n        controlParam3:setName(\"Size\")\r\n        controlParam4:setName(\"Pre Delay\")\r\n        controlParam5:setName(\"Low Band Level\")\r\n        controlParam6:setName(\"High Band Level\")\r\n        controlParam7:setName(\"Overdrive Type\")\r\n        controlParam8:setName(\"Distortion Output Level\")\r\n        controlParam9:setName(\"Wobble\")\r\n        controlParam10:setName(\"Mid Band Level\")\r\n    elseif (valueToggle == 13) then\r\n        valuePreset:setOverlayId(220)\r\n        controlParam1:setName(\"Mix\")\r\n        controlParam2:setName(\"Pitch A/B Mix\")\r\n        controlParam3:setName(\"Pitch Shift Up A\")\r\n        controlParam4:setName(\"Pitch Shift Down B\")\r\n        controlParam5:setName(\"Delay A\")\r\n        controlParam6:setName(\"Delay B\")\r\n        controlParam7:setName(\"Modulation Depth\")\r\n        controlParam8:setName(\"Modulation Rate\")\r\n        controlParam9:setName(\"Feedback\")\r\n        controlParam10:setName(\"Tone Control\")\r\n    elseif (valueToggle == 23) then\r\n        valuePreset:setOverlayId(221)\r\n        controlParam1:setName(\"Mix\")\r\n        controlParam2:setName(\"Delay Mix\")\r\n        controlParam3:setName(\"Delay A\")\r\n        controlParam4:setName(\"Delay B\")\r\n        controlParam5:setName(\"Feedback A\")\r\n        controlParam6:setName(\"Feedback B\")\r\n        controlParam7:setName(\"Mod Depth\")\r\n        controlParam8:setName(\"Mod Rate\")\r\n        controlParam9:setName(\"Filter\")\r\n        controlParam10:setName(\"Shape\")\r\n    elseif (valueToggle == 50) then\r\n        valuePreset:setOverlayId(222)\r\n        controlParam1:setName(\"Mix\")\r\n        controlParam2:setName(\"Decay\")\r\n        controlParam3:setName(\"Size\")\r\n        controlParam4:setName(\"Echo\")\r\n        controlParam5:setName(\"Low Band Shelving Level\")\r\n        controlParam6:setName(\"High Band Shelving Level\")\r\n        controlParam7:setName(\"Echo Feedback\")\r\n        controlParam8:setName(\"Modulation Rate\")\r\n        controlParam9:setName(\"Modulation Type and Depth\")\r\n        controlParam10:setName(\"Echo Tone\")\r\n    elseif (valueToggle == 27) then\r\n        valuePreset:setOverlayId(223)\r\n        controlParam1:setName(\"Mix\")\r\n        controlParam2:setName(\"Number of Taps\")\r\n        controlParam3:setName(\"Delay\")\r\n        controlParam4:setName(\"Feedback\")\r\n        controlParam5:setName(\"Modulation Depth\")\r\n        controlParam6:setName(\"Modulation Rate\")\r\n        controlParam7:setName(\"Spread\")\r\n        controlParam8:setName(\"Taper\")\r\n        controlParam9:setName(\"Chop\")\r\n        controlParam10:setName(\"Filter\")\r\n    elseif (valueToggle == 46) then\r\n        valuePreset:setOverlayId(224)\r\n        controlParam1:setName(\"Mix\")\r\n        controlParam2:setName(\"Drive\")\r\n        controlParam3:setName(\"Bass\")\r\n        controlParam4:setName(\"Mid\")\r\n        controlParam5:setName(\"Treble\")\r\n        controlParam6:setName(\"Fuzz\")\r\n        controlParam7:setName(\"Octave Mix\")\r\n        controlParam8:setName(\"Feedback\")\r\n        controlParam9:setName(\"Delay\")\r\n        controlParam10:setName(\"Pitch Shift\")\r\n    elseif (valueToggle == 2) then\r\n        valuePreset:setOverlayId(225)\r\n        controlParam1:setName(\"Mix\")\r\n        controlParam2:setName(\"Decay\")\r\n        controlParam3:setName(\"Size\")\r\n        controlParam4:setName(\"Pre Delay\")\r\n        controlParam5:setName(\"Low Band Damping\")\r\n        controlParam6:setName(\"High Band Damping\")\r\n        controlParam7:setName(\"Transducer Distance\")\r\n        controlParam8:setName(\"Diffusion\")\r\n        controlParam9:setName(\"Modulation Level\")\r\n        controlParam10:setName(\"Tone Control\")\r\n    elseif (valueToggle == 32) then\r\n        valuePreset:setOverlayId(226)\r\n        controlParam1:setName(\"Mix\")\r\n        controlParam2:setName(\"Wah Mode\")\r\n        controlParam3:setName(\"Frequency\")\r\n        controlParam4:setName(\"Resonance\")\r\n        controlParam5:setName(\"Attack Time\")\r\n        controlParam6:setName(\"Release Time\")\r\n        controlParam7:setName(\"Modulation Depth\")\r\n        controlParam8:setName(\"Modulation Rate\")\r\n        controlParam9:setName(\"Envelope Sensitivity\")\r\n        controlParam10:setName(\"Drive\")\r\n    elseif (valueToggle == 11) then\r\n        valuePreset:setOverlayId(227)\r\n        controlParam1:setName(\"Mix\")\r\n        controlParam2:setName(\"Pitch A and C/Pitch B and D Mix\")\r\n        controlParam3:setName(\"Pitch Shift A\")\r\n        controlParam4:setName(\"Pitch Shift B\")\r\n        controlParam5:setName(\"Delay D\")\r\n        controlParam6:setName(\"Delay Grouping\")\r\n        controlParam7:setName(\"Key\")\r\n        controlParam8:setName(\"Scale\")\r\n        controlParam9:setName(\"Pitch Shift C\")\r\n        controlParam10:setName(\"Pitch Shift D\")\r\n    elseif (valueToggle == 41) then\r\n        valuePreset:setOverlayId(228)\r\n        controlParam1:setName(\"Mix\")\r\n        controlParam2:setName(\"Resonance\")\r\n        controlParam3:setName(\"Decay\")\r\n        controlParam4:setName(\"Interval\")\r\n        controlParam5:setName(\"Feedback\")\r\n        controlParam6:setName(\"Modulation Depth\")\r\n        controlParam7:setName(\"Modulation Rate\")\r\n        controlParam8:setName(\"Input Mode\")\r\n        controlParam9:setName(\"Key\")\r\n        controlParam10:setName(\"Scale\")\r\n    elseif (valueToggle == 28) then\r\n        valuePreset:setOverlayId(229)\r\n        controlParam1:setName(\"Mix\")\r\n        controlParam2:setName(\"Reverse Delay\")\r\n        controlParam3:setName(\"Decay\")\r\n        controlParam4:setName(\"Feedback\")\r\n        controlParam5:setName(\"Filter Frequency\")\r\n        controlParam6:setName(\"Modulation Depth\")\r\n        controlParam7:setName(\"Modulation Rate\")\r\n        controlParam8:setName(\"Reverb Mix\")\r\n        controlParam9:setName(\"Reverb Decay\")\r\n        controlParam10:setName(\"Contour\")\r\n    elseif (valueToggle == 5) then\r\n        valuePreset:setOverlayId(230)\r\n        controlParam1:setName(\"Mix\")\r\n        controlParam2:setName(\"Decay\")\r\n        controlParam3:setName(\"Size\")\r\n        controlParam4:setName(\"Feedback\")\r\n        controlParam5:setName(\"Low Band Shelving Level\")\r\n        controlParam6:setName(\"High Band Shelving Level\")\r\n        controlParam7:setName(\"Late Dry Signal Level\")\r\n        controlParam8:setName(\"Diffusion\")\r\n        controlParam9:setName(\"Modulation Level\")\r\n        controlParam10:setName(\"Contour\")\r\n    elseif (valueToggle == 39) then\r\n        valuePreset:setOverlayId(231)\r\n        controlParam1:setName(\"Mix\")\r\n        controlParam2:setName(\"Frequency\")\r\n        controlParam3:setName(\"Depth\")\r\n        controlParam4:setName(\"Shape\")\r\n        controlParam5:setName(\"Mod Source\")\r\n        controlParam6:setName(\"Mod Rate\")\r\n        controlParam7:setName(\"Width\")\r\n        controlParam8:setName(\"Feedback\")\r\n        controlParam9:setName(\"Tone\")\r\n        controlParam10:setName(\"Output Level\")\r\n    elseif (valueToggle == 35) then\r\n        valuePreset:setOverlayId(232)\r\n        controlParam1:setName(\"Mix\")\r\n        controlParam2:setName(\"Slow/Fast Speed\")\r\n        controlParam3:setName(\"Acceleration\")\r\n        controlParam4:setName(\"Bass Rotor Level\")\r\n        controlParam5:setName(\"Horn Rotor Level\")\r\n        controlParam6:setName(\"Crossover Frequency\")\r\n        controlParam7:setName(\"Distance\")\r\n        controlParam8:setName(\"Balance\")\r\n        controlParam9:setName(\"Overdrive\")\r\n        controlParam10:setName(\"Tone\")\r\n    elseif (valueToggle == 45) then\r\n        valuePreset:setOverlayId(233)\r\n        controlParam1:setName(\"Mix\")\r\n        controlParam2:setName(\"Drive\")\r\n        controlParam3:setName(\"Bass\")\r\n        controlParam4:setName(\"Mid\")\r\n        controlParam5:setName(\"Treble\")\r\n        controlParam6:setName(\"Compressor\")\r\n        controlParam7:setName(\"Resonance\")\r\n        controlParam8:setName(\"Q\")\r\n        controlParam9:setName(\"Peak Frequency\")\r\n        controlParam10:setName(\"Output Level\")\r\n    elseif (valueToggle == 9) then\r\n        valuePreset:setOverlayId(234)\r\n        controlParam1:setName(\"Mix\")\r\n        controlParam2:setName(\"Decay\")\r\n        controlParam3:setName(\"Size\")\r\n        controlParam4:setName(\"Delay\")\r\n        controlParam5:setName(\"Low Band Decay\")\r\n        controlParam6:setName(\"High Band Decay\")\r\n        controlParam7:setName(\"Pitch Shift A\")\r\n        controlParam8:setName(\"Pitch Shift B\")\r\n        controlParam9:setName(\"Pitch Decay\")\r\n        controlParam10:setName(\"Mid Band Decay\")\r\n    elseif (valueToggle == 44) then\r\n        valuePreset:setOverlayId(235)\r\n        controlParam1:setName(\"Mix\")\r\n        controlParam2:setName(\"Decay\")\r\n        controlParam3:setName(\"Delay\")\r\n        controlParam4:setName(\"Modulation Depth\")\r\n        controlParam5:setName(\"Modulation Rate\")\r\n        controlParam6:setName(\"Reverb Size\")\r\n        controlParam7:setName(\"Pre-Delay\")\r\n        controlParam8:setName(\"Feedback\")\r\n        controlParam9:setName(\"Filter\")\r\n        controlParam10:setName(\"Chorus Level\")\r\n    elseif (valueToggle == 3) then\r\n        valuePreset:setOverlayId(236)\r\n        controlParam1:setName(\"Mix\")\r\n        controlParam2:setName(\"Decay\")\r\n        controlParam3:setName(\"Tension\")\r\n        controlParam4:setName(\"Number of Springs\")\r\n        controlParam5:setName(\"Low Band Damping\")\r\n        controlParam6:setName(\"High Band Damping\")\r\n        controlParam7:setName(\"Tremolo Intensity\")\r\n        controlParam8:setName(\"Tremolo Rate\")\r\n        controlParam9:setName(\"Modulation Level\")\r\n        controlParam10:setName(\"Resonance\")\r\n    elseif (valueToggle == 22) then\r\n        valuePreset:setOverlayId(237)\r\n        controlParam1:setName(\"Mix\")\r\n        controlParam2:setName(\"Delay Mix\")\r\n        controlParam3:setName(\"Delay A\")\r\n        controlParam4:setName(\"Delay B\")\r\n        controlParam5:setName(\"Feedback A\")\r\n        controlParam6:setName(\"Feedback B\")\r\n        controlParam7:setName(\"Saturation\")\r\n        controlParam8:setName(\"Tape Wow\")\r\n        controlParam9:setName(\"Tape Flutter\")\r\n        controlParam10:setName(\"Filter\")\r\n    elseif (valueToggle == 36) then\r\n        valuePreset:setOverlayId(238)\r\n        controlParam1:setName(\"Mix\")\r\n        controlParam2:setName(\"Depth\")\r\n        controlParam3:setName(\"Speed\")\r\n        controlParam4:setName(\"Shape\")\r\n        controlParam5:setName(\"Mod Source\")\r\n        controlParam6:setName(\"Mod Rate\")\r\n        controlParam7:setName(\"Width\")\r\n        controlParam8:setName(\"Tone\")\r\n        controlParam9:setName(\"Output Level\")\r\n        controlParam10:setName(\"Stereo Phase\")\r\n    elseif (valueToggle == 8) then\r\n        valuePreset:setOverlayId(239)\r\n        controlParam1:setName(\"Mix\")\r\n        controlParam2:setName(\"Decay\")\r\n        controlParam3:setName(\"Size\")\r\n        controlParam4:setName(\"Pre Delay\")\r\n        controlParam5:setName(\"Low Band Shelving Level\")\r\n        controlParam6:setName(\"High Band Shelving Level\")\r\n        controlParam7:setName(\"Tremolo Shape\")\r\n        controlParam8:setName(\"Tremolo Speed\")\r\n        controlParam9:setName(\"Tremolo Depth\")\r\n        controlParam10:setName(\"High Band Cutoff Frequency\")\r\n    elseif (valueToggle == 49) then\r\n        valuePreset:setOverlayId(240)\r\n        controlParam1:setName(\"Mix\")\r\n        controlParam2:setName(\"Chorus Type\")\r\n        controlParam3:setName(\"Depth\")\r\n        controlParam4:setName(\"Rate\")\r\n        controlParam5:setName(\"LFO Phase\")\r\n        controlParam6:setName(\"Detune\")\r\n        controlParam7:setName(\"Tone\")\r\n        controlParam8:setName(\"Feedback\")\r\n        controlParam9:setName(\"Width\")\r\n        controlParam10:setName(\"Output Level\")\r\n    elseif (valueToggle == 40) then\r\n        valuePreset:setOverlayId(241)\r\n        controlParam1:setName(\"Mix\")\r\n        controlParam2:setName(\"Number of Taps\")\r\n        controlParam3:setName(\"Delay\")\r\n        controlParam4:setName(\"Slurm\")\r\n        controlParam5:setName(\"Feedback\")\r\n        controlParam6:setName(\"Modulation Depth\")\r\n        controlParam7:setName(\"Modulation Rate\")\r\n        controlParam8:setName(\"Spread\")\r\n        controlParam9:setName(\"Taper\")\r\n        controlParam10:setName(\"Chop\")\r\n    elseif (valueToggle == 38) then\r\n        valuePreset:setOverlayId(242)\r\n        controlParam1:setName(\"Mix\")\r\n        controlParam2:setName(\"Depth\")\r\n        controlParam3:setName(\"Speed\")\r\n        controlParam4:setName(\"Shape\")\r\n        controlParam5:setName(\"Resonance\")\r\n        controlParam6:setName(\"Mod Source\")\r\n        controlParam7:setName(\"Mod Rate\")\r\n        controlParam8:setName(\"Width\")\r\n        controlParam9:setName(\"Feedback\")\r\n        controlParam10:setName(\"Filter\")\r\n    elseif (valueToggle == 21) then\r\n        valuePreset:setOverlayId(243)\r\n        controlParam1:setName(\"Mix\")\r\n        controlParam2:setName(\"Delay Mix\")\r\n        controlParam3:setName(\"Delay A\")\r\n        controlParam4:setName(\"Delay B\")\r\n        controlParam5:setName(\"Feedback A\")\r\n        controlParam6:setName(\"Feedback B\")\r\n        controlParam7:setName(\"Bits\")\r\n        controlParam8:setName(\"Modulation Depth\")\r\n        controlParam9:setName(\"Modulation Speed\")\r\n        controlParam10:setName(\"Filter\")\r\n    end\r\nend\r\n","devices":[{"id":16,"name":"Generic MIDI","instrumentId":"generic-controls","port":1,"channel":16}],"tiles":[{"id":"023013f2-9e1b-441a-b050-ae2486ef1934","reference":1,"slotId":6,"type":"fader","deviceId":16,"color":"ffffff","name":"input volume","categoryId":"control","values":[{"message":{"type":"cc7","deviceId":16,"parameterNumber":1,"min":0,"max":127}}],"visible":true,"variant":"thin","mode":""},{"id":"7f35191e-b79c-4786-80f7-3eaea9290c45","reference":3,"slotId":7,"type":"fader","deviceId":16,"color":"ffffff","name":"Parameter 1","categoryId":"control","values":[{"message":{"type":"cc7","deviceId":16,"parameterNumber":22,"min":0,"max":127}}],"visible":true,"variant":"thin","mode":""},{"id":"d5d83de5-3404-46e9-9a2b-4d5e4a0fbe30","reference":4,"slotId":8,"type":"fader","deviceId":16,"color":"ffffff","name":"Parameter 2","categoryId":"control","values":[{"message":{"type":"cc7","deviceId":16,"parameterNumber":23,"min":0,"max":127}}],"visible":true,"variant":"thin","mode":""},{"id":"753b48e8-517c-4600-b0d4-ccd0555314af","reference":5,"slotId":9,"type":"fader","deviceId":16,"color":"ffffff","name":"PARAMETER 3","categoryId":"control","values":[{"message":{"type":"cc7","deviceId":16,"parameterNumber":24,"min":0,"max":127}}],"visible":true,"variant":"thin","mode":""},{"id":"46e1f0cf-baaf-4063-a69f-3faf9dea8784","reference":6,"slotId":10,"type":"fader","deviceId":16,"color":"ffffff","name":"PARAMETER 4","categoryId":"control","values":[{"message":{"type":"cc7","deviceId":16,"parameterNumber":25,"min":0,"max":127}}],"visible":true,"variant":"thin","mode":""},{"id":"be7f085c-86b2-4732-91e5-976b8870c56a","reference":7,"slotId":11,"type":"fader","deviceId":16,"color":"ffffff","name":"PARAMTER 5","categoryId":"control","values":[{"message":{"type":"cc7","deviceId":16,"parameterNumber":26,"min":0,"max":127}}],"visible":true,"variant":"thin","mode":""},{"id":"9114195c-02fd-48b8-a9d1-ede74cb15fb9","reference":2,"slotId":18,"type":"fader","deviceId":16,"color":"ffffff","name":"output volume","categoryId":"control","values":[{"message":{"type":"cc7","deviceId":16,"parameterNumber":2,"min":0,"max":127}}],"visible":true,"variant":"thin","mode":""},{"id":"9190f6a1-4f25-4595-9041-c3bb01c51604","reference":8,"slotId":19,"type":"fader","deviceId":16,"color":"ffffff","name":"PARAMETER 6","categoryId":"control","values":[{"message":{"type":"cc7","deviceId":16,"parameterNumber":27,"min":0,"max":127}}],"visible":true,"variant":"thin","mode":""},{"id":"57a521a1-3a87-4c34-901a-fbe8dad2f51b","reference":9,"slotId":20,"type":"fader","deviceId":16,"color":"ffffff","name":"PARAMETER 7","categoryId":"control","values":[{"message":{"type":"cc7","deviceId":16,"parameterNumber":28,"min":0,"max":127}}],"visible":true,"variant":"thin","mode":""},{"id":"ff883e47-9993-4d15-b56d-640c2e4a6396","reference":10,"slotId":21,"type":"fader","deviceId":16,"color":"ffffff","name":"PARAMETER 8","categoryId":"control","values":[{"message":{"type":"cc7","deviceId":16,"parameterNumber":29,"min":0,"max":127}}],"visible":true,"variant":"thin","mode":""},{"id":"585a8abe-6364-44a9-b30f-c1da0d76bcc9","reference":11,"slotId":22,"type":"fader","deviceId":16,"color":"ffffff","name":"PARAMETER 9","categoryId":"control","values":[{"message":{"type":"cc7","deviceId":16,"parameterNumber":30,"min":0,"max":127}}],"visible":true,"variant":"thin","mode":""},{"id":"81cb7f25-e2db-4719-a2cd-fd905c2c01eb","reference":12,"slotId":23,"type":"fader","deviceId":16,"color":"ffffff","name":"PARAMETER 10","categoryId":"control","values":[{"message":{"type":"cc7","deviceId":16,"parameterNumber":31,"min":0,"max":127}}],"visible":true,"variant":"thin","mode":""},{"id":"8a9ac08c-4334-4c3c-9f92-9e3961afc0b4","reference":13,"slotId":31,"type":"list","deviceId":16,"color":"ffffff","name":"Algorithm","categoryId":"control","values":[{"message":{"type":"virtual","deviceId":16,"parameterNumber":32},"textValues":[],"function":"toggleAlgo"}],"visible":true},{"id":"5e00f174-55b3-4dc3-af23-01ab7ef7cf0c","reference":14,"slotId":32,"type":"list","deviceId":16,"color":"ffffff","name":"Effect","categoryId":"control","values":[{"message":{"type":"virtual","deviceId":16,"parameterNumber":33},"textValues":[],"function":"togglePreset"}],"visible":true,"variant":""},{"id":"a0f1a094-73d8-446e-8768-a721d768d52d","reference":15,"slotId":33,"type":"list","deviceId":16,"color":"ffffff","name":"Preset","categoryId":"control","values":[{"message":{"type":"program","deviceId":16},"textValues":[{"value":0,"label":"Option A"},{"value":1,"label":"Option B"},{"value":2,"label":"Option C"}]}],"visible":true}],"pages":[{"id":1,"name":"Page 1"}],"categories":[],"firstPageId":1}
</file>

<file path="scripts/01_hello_world.lua">
-- ============================================================================
-- SCRIPT 1: Hello World & Basics
-- Purpose: Learn the Electra One Lua environment fundamentals
-- ============================================================================
-- This script demonstrates:
--   • print() for debugging via the web console
--   • Preset lifecycle callbacks (onLoad, onReady)
--   • Accessing controller info
--   • Basic timer usage
-- ============================================================================

-- SETUP SECTION - runs when script loads
-- ============================================================================
print("=== Electra One Lua Script Loaded ===")

-- Query controller information
local model = controller.getModel()
local firmware = controller.getFirmwareVersion()
print("Model: " .. model)
print("Firmware: " .. firmware)

-- Check uptime (milliseconds since power on)
local uptime = controller.uptime()
print("Uptime: " .. math.floor(uptime / 1000) .. " seconds")

-- PRESET CALLBACKS - key lifecycle hooks
-- ============================================================================

-- Called immediately after preset loads, BEFORE default values initialize
function preset.onLoad()
    print(">> preset.onLoad() - Preset is loading...")
    -- Good place for: variable initialization, pre-setup
end

-- Called when preset is fully ready (controls initialized, values set)
function preset.onReady()
    print(">> preset.onReady() - Preset ready to use!")
    -- Good place for: final setup, triggering initial MIDI, UI updates
    
    -- Show a message in the status bar
    info.setText("Hello from Lua!")
end

-- Called when user switches TO this preset
function preset.onEnter()
    print(">> preset.onEnter() - Activated this preset")
end

-- Called when user switches AWAY from this preset
function preset.onLeave()
    print(">> preset.onLeave() - Leaving preset")
end

-- TIMER DEMO - timed execution
-- ============================================================================
-- The timer fires onTick() at set intervals

local tickCount = 0
local maxTicks = 10  -- Only run 10 times for demo

function timer.onTick()
    tickCount = tickCount + 1
    print("Timer tick #" .. tickCount)
    
    -- Disable timer after max ticks (so it doesn't run forever)
    if tickCount >= maxTicks then
        timer.disable()
        print("Timer disabled after " .. maxTicks .. " ticks")
        info.setText("Timer demo complete!")
    end
end

-- Initialize timer: 500ms period (2 ticks per second)
function startTimerDemo()
    tickCount = 0
    timer.setPeriod(500)
    timer.enable()
    print("Timer started at 500ms period")
end

-- Call this from a control's "function" callback to start the demo
-- Or uncomment the next line to auto-start:
-- startTimerDemo()

-- ============================================================================
-- HOW TO USE THIS SCRIPT:
-- 1. Go to https://app.electra.one and create a new preset
-- 2. Add the Lua script in the Lua editor tab
-- 3. Open the Console log (bottom panel) to see print() output
-- 4. Upload to your Electra One Mini
-- ============================================================================
</file>

<file path="scripts/02_midi_io.lua">
-- ============================================================================
-- SCRIPT 2: MIDI Input/Output
-- Purpose: Learn to send and receive MIDI messages
-- ============================================================================
-- This script demonstrates:
--   • Sending various MIDI message types
--   • Receiving and processing incoming MIDI
--   • MIDI callbacks for specific message types
--   • Working with SysEx
-- ============================================================================
-- Great for: Ableton Live integration, controlling hardware synths
-- ============================================================================

print("=== MIDI I/O Script Loaded ===")

-- SENDING MIDI MESSAGES
-- ============================================================================
-- PORT_1 = MIDI port 1, PORT_2 = MIDI port 2
-- For USB MIDI to Ableton, typically use PORT_1

-- Function to send a CC message (e.g., for Ableton device control)
function sendCC(channel, ccNumber, value)
    midi.sendControlChange(PORT_1, channel, ccNumber, value)
    print(string.format("Sent CC: ch=%d cc=%d val=%d", channel, ccNumber, value))
end

-- Function to send program change (switch patches on a synth)
function sendProgramChange(channel, program)
    midi.sendProgramChange(PORT_1, channel, program)
    print(string.format("Sent Program Change: ch=%d prog=%d", channel, program))
end

-- Function to send a note (useful for triggering clips in Ableton)
function sendNote(channel, note, velocity, durationMs)
    midi.sendNoteOn(PORT_1, channel, note, velocity)
    print(string.format("Note ON: ch=%d note=%d vel=%d", channel, note, velocity))
    
    -- Schedule note off (using simple delay - see transport for better timing)
    -- Note: delay() pauses execution - use sparingly!
    if durationMs and durationMs > 0 then
        helpers.delay(durationMs)
        midi.sendNoteOff(PORT_1, channel, note, 0)
        print("Note OFF")
    end
end

-- Send NRPN (14-bit high-res control - common on modern synths)
function sendNRPN(channel, paramNumber, value)
    -- lsbFirst=false, reset=true (sends RPN reset after)
    midi.sendNrpn(PORT_1, channel, paramNumber, value, false, true)
    print(string.format("Sent NRPN: param=%d val=%d", paramNumber, value))
end

-- Send 14-bit CC (for high-resolution control)
function sendCC14(channel, ccNumber, value)
    -- ccNumber should be 0-31 (MSB), LSB is automatically ccNumber+32
    midi.sendControlChange14Bit(PORT_1, channel, ccNumber, value, false)
    print(string.format("Sent 14-bit CC: cc=%d val=%d", ccNumber, value))
end

-- RECEIVING MIDI - Callbacks
-- ============================================================================
-- Define these functions to handle specific incoming MIDI types

-- Generic handler - catches ALL incoming MIDI
function midi.onMessage(midiInput, midiMessage)
    -- midiInput.interface tells us where it came from
    -- midiInput.port is the port number
    
    if midiMessage.type ~= CLOCK then  -- Filter out clock to reduce spam
        print(string.format("MIDI: type=%d ch=%d data1=%d data2=%d from=%s",
            midiMessage.type,
            midiMessage.channel or 0,
            midiMessage.data1 or 0,
            midiMessage.data2 or 0,
            midiInput.interface))
    end
end

-- Specific handler for Control Change
function midi.onControlChange(midiInput, channel, controllerNumber, value)
    print(string.format("CC received: ch=%d cc=%d val=%d", 
        channel, controllerNumber, value))
    
    -- Example: Echo received CC to status bar
    info.setText(string.format("CC %d = %d", controllerNumber, value))
    
    -- Example: Map incoming CC to a control value
    -- parameterMap.set(deviceId, PT_CC7, controllerNumber, value)
end

-- Specific handler for Note On
function midi.onNoteOn(midiInput, channel, noteNumber, velocity)
    print(string.format("Note ON: ch=%d note=%d vel=%d", 
        channel, noteNumber, velocity))
end

-- Specific handler for Note Off
function midi.onNoteOff(midiInput, channel, noteNumber, velocity)
    print(string.format("Note OFF: ch=%d note=%d", channel, noteNumber))
end

-- Specific handler for Program Change
function midi.onProgramChange(midiInput, channel, programNumber)
    print(string.format("Program Change: ch=%d prog=%d", channel, programNumber))
    info.setText("Program: " .. programNumber)
end

-- Specific handler for Pitch Bend
function midi.onPitchBend(midiInput, channel, value)
    -- value is -8192 to +8191, center is 0
    print(string.format("Pitch Bend: ch=%d val=%d", channel, value))
end

-- SysEx handler - for patch dumps, deep editing, etc.
function midi.onSysex(midiInput, sysexBlock)
    local length = sysexBlock:getLength()
    local mfgId = sysexBlock:getManufacturerSysexId()
    
    print(string.format("SysEx received: %d bytes, Manufacturer ID: %d", 
        length, mfgId))
    
    -- Example: print first few bytes
    local preview = "Bytes: "
    for i = 1, math.min(10, length) do
        preview = preview .. string.format("%02X ", sysexBlock:peek(i))
    end
    print(preview)
end

-- MIDI CLOCK & TRANSPORT
-- ============================================================================
-- Use transport module for external clock sync (better than timer for sync)

-- Enable to receive transport messages
transport.enable()

function transport.onStart(midiInput)
    print("TRANSPORT: Start")
    info.setText("▶ Playing")
end

function transport.onStop(midiInput)
    print("TRANSPORT: Stop")
    info.setText("■ Stopped")
end

function transport.onContinue(midiInput)
    print("TRANSPORT: Continue")
end

-- Clock is called 24 times per quarter note
local clockPulseCount = 0
function transport.onClock(midiInput)
    clockPulseCount = clockPulseCount + 1
    
    -- Log every beat (24 pulses = 1 quarter note)
    if clockPulseCount % 24 == 0 then
        print("Beat: " .. (clockPulseCount / 24))
    end
end

-- EXAMPLE: Preset ready hook to send initial MIDI
-- ============================================================================
function preset.onReady()
    print("MIDI I/O preset ready")
    
    -- Example: Request all notes off on channel 1 (CC 123)
    -- midi.sendControlChange(PORT_1, 1, 123, 0)
    
    info.setText("MIDI I/O Ready")
end

-- ============================================================================
-- TEST FUNCTIONS - call these from control callbacks
-- ============================================================================

-- Trigger a C3 note for 200ms
function testNote()
    sendNote(1, 60, 100, 200)
end

-- Send a test CC sweep
function testCCSweep()
    for i = 0, 127, 16 do
        sendCC(1, 1, i)  -- Mod wheel sweep
        helpers.delay(50)
    end
end

-- ============================================================================
-- NOTES FOR ABLETON LIVE:
-- 1. Set Electra One as a MIDI input in Live's preferences
-- 2. Enable "Remote" for the Electra One port
-- 3. Use MIDI Map mode to assign CC messages to parameters
-- 4. For transport sync, ensure Live is sending MIDI clock
-- ============================================================================
</file>

<file path="scripts/03_control_manipulation.lua">
-- ============================================================================
-- SCRIPT 3: Control Manipulation & Dynamic UI
-- Purpose: Learn to modify controls, pages, and groups at runtime
-- ============================================================================
-- This script demonstrates:
--   • Getting and modifying control properties
--   • Showing/hiding controls dynamically
--   • Changing control positions (slots)
--   • Working with pages and groups
--   • Value callbacks and formatters
-- ============================================================================
-- Use case: Context-sensitive interfaces that change based on synth state
-- ============================================================================

print("=== Control Manipulation Script Loaded ===")

-- CONTROL ACCESS
-- ============================================================================
-- controls.get(refId) retrieves a control by its reference number
-- Find ref numbers in the Preset Editor's control properties panel

-- Example: Get a control and print its properties
function inspectControl(refId)
    local ctrl = controls.get(refId)
    if ctrl then
        print("--- Control " .. refId .. " ---")
        print("  Name: " .. ctrl:getName())
        print("  Visible: " .. tostring(ctrl:isVisible()))
        print("  Color: " .. string.format("0x%06X", ctrl:getColor()))
        
        -- Get bounds (position and size)
        local bounds = ctrl:getBounds()
        print(string.format("  Position: x=%d y=%d w=%d h=%d",
            bounds[X], bounds[Y], bounds[WIDTH], bounds[HEIGHT]))
        
        -- List value IDs
        local valueIds = ctrl:getValueIds()
        print("  Values: " .. table.concat(valueIds, ", "))
    end
end

-- DYNAMIC VISIBILITY
-- ============================================================================
-- Show/hide controls based on context (e.g., synth mode selection)

-- Hide all controls in a list
function hideControls(controlIds)
    for _, id in ipairs(controlIds) do
        local ctrl = controls.get(id)
        if ctrl then
            ctrl:setVisible(false)
        end
    end
end

-- Show all controls in a list
function showControls(controlIds)
    for _, id in ipairs(controlIds) do
        local ctrl = controls.get(id)
        if ctrl then
            ctrl:setVisible(true)
        end
    end
end

-- Example: Define control groups for different synth modes
-- (Replace with your actual control ref IDs)
local oscillatorControls = {1, 2, 3, 4}      -- OSC parameters
local filterControls = {5, 6, 7, 8}          -- Filter parameters
local envelopeControls = {9, 10, 11, 12}     -- Envelope parameters

-- Switch display mode (call from a List control)
function switchMode(valueObject, value)
    -- value 0 = OSC, 1 = Filter, 2 = Envelope
    
    -- Hide all
    hideControls(oscillatorControls)
    hideControls(filterControls)
    hideControls(envelopeControls)
    
    -- Show selected group
    if value == 0 then
        showControls(oscillatorControls)
        info.setText("OSC Mode")
    elseif value == 1 then
        showControls(filterControls)
        info.setText("Filter Mode")
    elseif value == 2 then
        showControls(envelopeControls)
        info.setText("Envelope Mode")
    end
end

-- MOVING CONTROLS
-- ============================================================================
-- Reassign controls to different slots on the grid

-- Move a control to a specific slot (1-36 on mkII, varies on Mini)
function moveToSlot(controlId, slot)
    local ctrl = controls.get(controlId)
    if ctrl then
        ctrl:setSlot(slot)
        print("Moved control " .. controlId .. " to slot " .. slot)
    end
end

-- Move control to slot on specific page
function moveToSlotOnPage(controlId, slot, pageId)
    local ctrl = controls.get(controlId)
    if ctrl then
        ctrl:setSlot(slot, pageId)
    end
end

-- Manual positioning with pixel coordinates
function setControlPosition(controlId, x, y, width, height)
    local ctrl = controls.get(controlId)
    if ctrl then
        ctrl:setBounds({x, y, width, height})
    end
end

-- CONTROL PROPERTIES
-- ============================================================================

-- Change control name dynamically
function setControlName(controlId, newName)
    local ctrl = controls.get(controlId)
    if ctrl then
        ctrl:setName(newName)
    end
end

-- Change control color
function setControlColor(controlId, color)
    -- color is 24-bit RGB, e.g., 0xFF0000 = red
    local ctrl = controls.get(controlId)
    if ctrl then
        ctrl:setColor(color)
    end
end

-- Example: Flash a control red briefly (for alerts)
function flashControl(controlId)
    local ctrl = controls.get(controlId)
    if ctrl then
        local originalColor = ctrl:getColor()
        ctrl:setColor(0xFF0000)
        helpers.delay(200)
        ctrl:setColor(originalColor)
    end
end

-- PAGE MANAGEMENT
-- ============================================================================

-- Switch to a different page
function goToPage(pageId)
    pages.display(pageId)
    print("Switched to page " .. pageId)
end

-- Get info about current page
function getCurrentPageInfo()
    local page = pages.getActive()
    print("Current page: " .. page:getId() .. " - " .. page:getName())
end

-- Rename a page
function renamePage(pageId, newName)
    local page = pages.get(pageId)
    if page then
        page:setName(newName)
    end
end

-- Hide a page (won't show in page selector)
function hidePage(pageId, hidden)
    local page = pages.get(pageId)
    if page then
        page:setHidden(hidden)
    end
end

-- Page change callback
function pages.onChange(newPageId, oldPageId)
    print(string.format("Page changed: %d -> %d", oldPageId, newPageId))
    info.setText("Page " .. newPageId)
end

-- GROUP MANAGEMENT
-- ============================================================================
-- Groups are visual containers for organizing controls

function setGroupLabel(groupId, label)
    local group = groups.get(groupId)
    if group then
        group:setLabel(label)
    end
end

function setGroupColor(groupId, color)
    local group = groups.get(groupId)
    if group then
        group:setColor(color)
    end
end

-- VALUE CALLBACKS
-- ============================================================================
-- Assign these to controls in the preset editor's "Function" field

-- Example: Called when a fader value changes
-- The valueObject lets you access the control and message
function onValueChange(valueObject, value)
    local control = valueObject:getControl()
    local message = valueObject:getMessage()
    
    print(string.format("%s changed to %d (MIDI: %d)",
        control:getName(),
        value,
        message:getValue()))
end

-- Example: Change color based on value threshold
function colorByValue(valueObject, value)
    local control = valueObject:getControl()
    
    if value > 100 then
        control:setColor(0xFF0000)  -- Red = hot
    elseif value > 50 then
        control:setColor(0xFFFF00)  -- Yellow = warm
    else
        control:setColor(0x00FF00)  -- Green = cool
    end
end

-- VALUE FORMATTERS
-- ============================================================================
-- Return a string to display instead of the raw value

-- Example: Display as percentage
function formatPercent(valueObject, value)
    return string.format("%d%%", value)
end

-- Example: Display as dB
function formatDb(valueObject, value)
    -- Assuming 0-127 maps to -inf to +6dB
    if value == 0 then
        return "-∞ dB"
    else
        local db = (value / 127) * 6 - 6  -- -6 to 0 range example
        return string.format("%.1f dB", db)
    end
end

-- Example: Display note names
local noteNames = {"C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"}
function formatNote(valueObject, value)
    local octave = math.floor(value / 12) - 2
    local note = noteNames[(value % 12) + 1]
    return note .. octave
end

-- Example: Display frequency (for filter cutoff)
function formatFrequency(valueObject, value)
    -- Assuming exponential mapping 20Hz to 20kHz over 0-127
    local freq = 20 * math.exp(value / 127 * math.log(1000))
    if freq >= 1000 then
        return string.format("%.1f kHz", freq / 1000)
    else
        return string.format("%.0f Hz", freq)
    end
end

-- OVERLAYS (List Items)
-- ============================================================================
-- Create dynamic lists for controls

function createWaveformOverlay()
    local waveforms = {
        {value = 0, label = "Sine"},
        {value = 1, label = "Triangle"},
        {value = 2, label = "Saw"},
        {value = 3, label = "Square"},
        {value = 4, label = "Noise"}
    }
    
    overlays.create(100, waveforms)  -- ID 100
    print("Created waveform overlay")
end

-- Assign overlay to a control's value
function assignOverlay(controlId, overlayId)
    local ctrl = controls.get(controlId)
    if ctrl then
        local value = ctrl:getValue("value")
        value:setOverlayId(overlayId)
    end
end

-- PRESET READY
-- ============================================================================
function preset.onReady()
    print("Control Manipulation preset ready")
    
    -- Create custom overlays
    -- createWaveformOverlay()
    
    -- Initial UI setup
    -- hideControls(filterControls)
    -- hideControls(envelopeControls)
    
    info.setText("Controls Ready")
end

-- ============================================================================
-- USAGE IN PRESET EDITOR:
-- 1. Create controls with sequential ref IDs
-- 2. In a List control's "Function" field, enter: switchMode
-- 3. In Fader "Function" fields, enter callback names like: colorByValue
-- 4. In "Formatter" fields, enter: formatPercent, formatDb, etc.
-- ============================================================================
</file>

<file path="scripts/04_midi_lfo.lua">
-- ============================================================================
-- SCRIPT 4: MIDI LFO Generator
-- Purpose: Create a software LFO that modulates CC values
-- ============================================================================
-- This script demonstrates:
--   • Timer-based periodic execution
--   • parameterMap for value manipulation
--   • Math functions for waveform generation
--   • State management and user-adjustable parameters
--   • Graphics API for custom control visualization
-- ============================================================================
-- Perfect for: Adding modulation to synths that lack built-in LFOs
-- ============================================================================

print("=== MIDI LFO Generator Loaded ===")

-- LFO STATE
-- ============================================================================
local lfo = {
    enabled = false,
    phase = 0,              -- Current position in cycle (0-1)
    rate = 1.0,             -- Hz (cycles per second)
    depth = 64,             -- Modulation depth (0-127)
    waveform = 0,           -- 0=sine, 1=triangle, 2=saw, 3=square, 4=random
    targetCC = 1,           -- CC number to modulate (default: mod wheel)
    targetChannel = 1,      -- MIDI channel
    centerValue = 64,       -- Center point of modulation
    lastOutput = 0,         -- Last calculated value (for display)
}

-- Waveform names for display
local waveformNames = {"Sine", "Triangle", "Saw Up", "Square", "Random"}

-- WAVEFORM GENERATORS
-- ============================================================================
-- Each returns a value from -1 to +1

function generateSine(phase)
    return math.sin(phase * 2 * math.pi)
end

function generateTriangle(phase)
    if phase < 0.25 then
        return phase * 4
    elseif phase < 0.75 then
        return 1 - (phase - 0.25) * 4
    else
        return -1 + (phase - 0.75) * 4
    end
end

function generateSawUp(phase)
    return phase * 2 - 1
end

function generateSquare(phase)
    return phase < 0.5 and 1 or -1
end

function generateRandom(phase)
    -- Sample-and-hold style random
    return math.random() * 2 - 1
end

-- Get waveform value based on current waveform type
function getWaveformValue(phase, waveformType)
    if waveformType == 0 then
        return generateSine(phase)
    elseif waveformType == 1 then
        return generateTriangle(phase)
    elseif waveformType == 2 then
        return generateSawUp(phase)
    elseif waveformType == 3 then
        return generateSquare(phase)
    elseif waveformType == 4 then
        return generateRandom(phase)
    end
    return 0
end

-- LFO CORE
-- ============================================================================

-- Calculate the LFO output value
function calculateLFO()
    -- Get raw waveform (-1 to +1)
    local raw = getWaveformValue(lfo.phase, lfo.waveform)
    
    -- Scale by depth and add to center
    local scaled = raw * lfo.depth
    local output = lfo.centerValue + scaled
    
    -- Clamp to valid MIDI range
    output = math.max(0, math.min(127, math.floor(output)))
    
    lfo.lastOutput = output
    return output
end

-- Advance the LFO phase based on timer period
local TIMER_PERIOD_MS = 20  -- 50 Hz update rate

function advancePhase()
    local periodSeconds = 1 / lfo.rate
    local phaseIncrement = (TIMER_PERIOD_MS / 1000) / periodSeconds
    lfo.phase = (lfo.phase + phaseIncrement) % 1.0
end

-- TIMER CALLBACK
-- ============================================================================
function timer.onTick()
    if not lfo.enabled then
        return
    end
    
    -- Calculate and send LFO value
    local output = calculateLFO()
    
    -- Send as CC message
    midi.sendControlChange(PORT_1, lfo.targetChannel, lfo.targetCC, output)
    
    -- Advance phase for next tick
    advancePhase()
end

-- LFO CONTROL FUNCTIONS
-- ============================================================================
-- These can be called from control callbacks

function enableLFO(valueObject, value)
    lfo.enabled = (value > 0)
    
    if lfo.enabled then
        lfo.phase = 0  -- Reset phase on enable
        timer.enable()
        info.setText("LFO ON")
        print("LFO enabled")
    else
        timer.disable()
        info.setText("LFO OFF")
        print("LFO disabled")
    end
end

function setLFORate(valueObject, value)
    -- Map 0-127 to 0.1-10 Hz (logarithmic feels better)
    lfo.rate = 0.1 * math.exp(value / 127 * math.log(100))
    print(string.format("LFO Rate: %.2f Hz", lfo.rate))
end

function setLFODepth(valueObject, value)
    lfo.depth = value / 2  -- 0-127 -> 0-63.5 (half range each direction)
    print(string.format("LFO Depth: %d", lfo.depth))
end

function setLFOWaveform(valueObject, value)
    lfo.waveform = value
    print("LFO Waveform: " .. waveformNames[value + 1])
end

function setLFOTargetCC(valueObject, value)
    lfo.targetCC = value
    print("LFO Target CC: " .. value)
end

function setLFOCenter(valueObject, value)
    lfo.centerValue = value
    print("LFO Center: " .. value)
end

-- VALUE FORMATTERS
-- ============================================================================

function formatLFORate(valueObject, value)
    local rate = 0.1 * math.exp(value / 127 * math.log(100))
    return string.format("%.1f Hz", rate)
end

function formatLFOWaveform(valueObject, value)
    return waveformNames[value + 1] or "?"
end

-- CUSTOM CONTROL: LFO VISUALIZER
-- ============================================================================
-- This draws the LFO waveform on a Custom control type

function drawLFOVisualizer(control, x, y, width, height)
    -- Background
    graphics.setColor(0x202020)
    graphics.fillRect(x, y, width, height)
    
    -- Border
    graphics.setColor(0x404040)
    graphics.drawRect(x, y, width, height)
    
    -- Center line
    graphics.setColor(0x606060)
    local centerY = y + height / 2
    graphics.drawLine(x, centerY, x + width, centerY)
    
    -- Draw waveform
    graphics.setColor(0x00FFFF)  -- Cyan
    
    local prevY = nil
    for i = 0, width - 1 do
        local phase = i / width
        local value = getWaveformValue(phase, lfo.waveform)
        local drawY = centerY - value * (height / 2 - 4)
        
        if prevY then
            graphics.drawLine(x + i - 1, prevY, x + i, drawY)
        end
        prevY = drawY
    end
    
    -- Draw current phase position
    local phaseX = x + lfo.phase * width
    graphics.setColor(0xFF0000)  -- Red playhead
    graphics.drawLine(phaseX, y + 2, phaseX, y + height - 2)
    
    -- Draw current output value as a dot
    local outputY = centerY - (lfo.lastOutput - 64) / 64 * (height / 2 - 4)
    graphics.setColor(0xFFFF00)  -- Yellow
    graphics.fillCircle(phaseX, outputY, 4)
end

-- Register the paint callback for a Custom control
-- (You'd call this in preset.onReady() with the control's ref ID)
function setupVisualizer(controlId)
    local ctrl = controls.get(controlId)
    if ctrl then
        ctrl:setPaintCallback(function(control)
            local bounds = control:getBounds()
            drawLFOVisualizer(control, bounds[X], bounds[Y], 
                             bounds[WIDTH], bounds[HEIGHT])
        end)
        print("LFO Visualizer setup on control " .. controlId)
    end
end

-- Repaint the visualizer periodically
local repaintCounter = 0
local REPAINT_INTERVAL = 5  -- Every 5 timer ticks (100ms at 50Hz)

function timer.onTick()
    if not lfo.enabled then
        return
    end
    
    -- Calculate and send LFO value
    local output = calculateLFO()
    midi.sendControlChange(PORT_1, lfo.targetChannel, lfo.targetCC, output)
    
    -- Advance phase
    advancePhase()
    
    -- Repaint visualizer less frequently (for performance)
    repaintCounter = repaintCounter + 1
    if repaintCounter >= REPAINT_INTERVAL then
        repaintCounter = 0
        -- If you have a visualizer control, repaint it here
        -- local vizControl = controls.get(VISUALIZER_CONTROL_ID)
        -- if vizControl then vizControl:repaint() end
    end
end

-- PRESET INITIALIZATION
-- ============================================================================

function preset.onReady()
    print("MIDI LFO preset ready")
    
    -- Initialize timer at 50Hz (20ms period)
    timer.setPeriod(TIMER_PERIOD_MS)
    
    -- Create waveform overlay for list control
    overlays.create(1, {
        {value = 0, label = "Sine"},
        {value = 1, label = "Triangle"},
        {value = 2, label = "Saw Up"},
        {value = 3, label = "Square"},
        {value = 4, label = "Random"}
    })
    
    -- Setup visualizer if you have a Custom control for it
    -- setupVisualizer(YOUR_CUSTOM_CONTROL_ID)
    
    info.setText("LFO Ready")
end

-- ============================================================================
-- PRESET SETUP GUIDE:
-- 
-- Create these controls in the Preset Editor:
-- 1. PAD "Enable" - Function: enableLFO
-- 2. FADER "Rate" - Function: setLFORate, Formatter: formatLFORate
-- 3. FADER "Depth" - Function: setLFODepth
-- 4. LIST "Wave" - Function: setLFOWaveform, Overlay ID: 1
-- 5. FADER "Target CC" - Function: setLFOTargetCC, Min: 0, Max: 127
-- 6. FADER "Center" - Function: setLFOCenter, Default: 64
-- 7. (Optional) CUSTOM "Display" - for waveform visualization
--
-- All controls should use Device ID 1 (or create a virtual device)
-- ============================================================================
</file>

<file path="scripts/05_sysex_patch_handler.lua">
-- ============================================================================
-- SCRIPT 4: MIDI LFO Generator
-- Purpose: Create a software LFO that modulates CC values
-- ============================================================================
-- This script demonstrates:
--   • Timer-based periodic execution
--   • parameterMap for value manipulation
--   • Math functions for waveform generation
--   • State management and user-adjustable parameters
--   • Graphics API for custom control visualization
-- ============================================================================
-- Perfect for: Adding modulation to synths that lack built-in LFOs
-- ============================================================================

print("=== MIDI LFO Generator Loaded ===")

-- LFO STATE
-- ============================================================================
local lfo = {
    enabled = false,
    phase = 0,              -- Current position in cycle (0-1)
    rate = 1.0,             -- Hz (cycles per second)
    depth = 64,             -- Modulation depth (0-127)
    waveform = 0,           -- 0=sine, 1=triangle, 2=saw, 3=square, 4=random
    targetCC = 1,           -- CC number to modulate (default: mod wheel)
    targetChannel = 1,      -- MIDI channel
    centerValue = 64,       -- Center point of modulation
    lastOutput = 0,         -- Last calculated value (for display)
}

-- Waveform names for display
local waveformNames = {"Sine", "Triangle", "Saw Up", "Square", "Random"}

-- WAVEFORM GENERATORS
-- ============================================================================
-- Each returns a value from -1 to +1

function generateSine(phase)
    return math.sin(phase * 2 * math.pi)
end

function generateTriangle(phase)
    if phase < 0.25 then
        return phase * 4
    elseif phase < 0.75 then
        return 1 - (phase - 0.25) * 4
    else
        return -1 + (phase - 0.75) * 4
    end
end

function generateSawUp(phase)
    return phase * 2 - 1
end

function generateSquare(phase)
    return phase < 0.5 and 1 or -1
end

function generateRandom(phase)
    -- Sample-and-hold style random
    return math.random() * 2 - 1
end

-- Get waveform value based on current waveform type
function getWaveformValue(phase, waveformType)
    if waveformType == 0 then
        return generateSine(phase)
    elseif waveformType == 1 then
        return generateTriangle(phase)
    elseif waveformType == 2 then
        return generateSawUp(phase)
    elseif waveformType == 3 then
        return generateSquare(phase)
    elseif waveformType == 4 then
        return generateRandom(phase)
    end
    return 0
end

-- LFO CORE
-- ============================================================================

-- Calculate the LFO output value
function calculateLFO()
    -- Get raw waveform (-1 to +1)
    local raw = getWaveformValue(lfo.phase, lfo.waveform)
    
    -- Scale by depth and add to center
    local scaled = raw * lfo.depth
    local output = lfo.centerValue + scaled
    
    -- Clamp to valid MIDI range
    output = math.max(0, math.min(127, math.floor(output)))
    
    lfo.lastOutput = output
    return output
end

-- Advance the LFO phase based on timer period
local TIMER_PERIOD_MS = 20  -- 50 Hz update rate

function advancePhase()
    local periodSeconds = 1 / lfo.rate
    local phaseIncrement = (TIMER_PERIOD_MS / 1000) / periodSeconds
    lfo.phase = (lfo.phase + phaseIncrement) % 1.0
end

-- TIMER CALLBACK
-- ============================================================================
function timer.onTick()
    if not lfo.enabled then
        return
    end
    
    -- Calculate and send LFO value
    local output = calculateLFO()
    
    -- Send as CC message
    midi.sendControlChange(PORT_1, lfo.targetChannel, lfo.targetCC, output)
    
    -- Advance phase for next tick
    advancePhase()
end

-- LFO CONTROL FUNCTIONS
-- ============================================================================
-- These can be called from control callbacks

function enableLFO(valueObject, value)
    lfo.enabled = (value > 0)
    
    if lfo.enabled then
        lfo.phase = 0  -- Reset phase on enable
        timer.enable()
        info.setText("LFO ON")
        print("LFO enabled")
    else
        timer.disable()
        info.setText("LFO OFF")
        print("LFO disabled")
    end
end

function setLFORate(valueObject, value)
    -- Map 0-127 to 0.1-10 Hz (logarithmic feels better)
    lfo.rate = 0.1 * math.exp(value / 127 * math.log(100))
    print(string.format("LFO Rate: %.2f Hz", lfo.rate))
end

function setLFODepth(valueObject, value)
    lfo.depth = value / 2  -- 0-127 -> 0-63.5 (half range each direction)
    print(string.format("LFO Depth: %d", lfo.depth))
end

function setLFOWaveform(valueObject, value)
    lfo.waveform = value
    print("LFO Waveform: " .. waveformNames[value + 1])
end

function setLFOTargetCC(valueObject, value)
    lfo.targetCC = value
    print("LFO Target CC: " .. value)
end

function setLFOCenter(valueObject, value)
    lfo.centerValue = value
    print("LFO Center: " .. value)
end

-- VALUE FORMATTERS
-- ============================================================================

function formatLFORate(valueObject, value)
    local rate = 0.1 * math.exp(value / 127 * math.log(100))
    return string.format("%.1f Hz", rate)
end

function formatLFOWaveform(valueObject, value)
    return waveformNames[value + 1] or "?"
end

-- CUSTOM CONTROL: LFO VISUALIZER
-- ============================================================================
-- This draws the LFO waveform on a Custom control type

function drawLFOVisualizer(control, x, y, width, height)
    -- Background
    graphics.setColor(0x202020)
    graphics.fillRect(x, y, width, height)
    
    -- Border
    graphics.setColor(0x404040)
    graphics.drawRect(x, y, width, height)
    
    -- Center line
    graphics.setColor(0x606060)
    local centerY = y + height / 2
    graphics.drawLine(x, centerY, x + width, centerY)
    
    -- Draw waveform
    graphics.setColor(0x00FFFF)  -- Cyan
    
    local prevY = nil
    for i = 0, width - 1 do
        local phase = i / width
        local value = getWaveformValue(phase, lfo.waveform)
        local drawY = centerY - value * (height / 2 - 4)
        
        if prevY then
            graphics.drawLine(x + i - 1, prevY, x + i, drawY)
        end
        prevY = drawY
    end
    
    -- Draw current phase position
    local phaseX = x + lfo.phase * width
    graphics.setColor(0xFF0000)  -- Red playhead
    graphics.drawLine(phaseX, y + 2, phaseX, y + height - 2)
    
    -- Draw current output value as a dot
    local outputY = centerY - (lfo.lastOutput - 64) / 64 * (height / 2 - 4)
    graphics.setColor(0xFFFF00)  -- Yellow
    graphics.fillCircle(phaseX, outputY, 4)
end

-- Register the paint callback for a Custom control
-- (You'd call this in preset.onReady() with the control's ref ID)
function setupVisualizer(controlId)
    local ctrl = controls.get(controlId)
    if ctrl then
        ctrl:setPaintCallback(function(control)
            local bounds = control:getBounds()
            drawLFOVisualizer(control, bounds[X], bounds[Y], 
                             bounds[WIDTH], bounds[HEIGHT])
        end)
        print("LFO Visualizer setup on control " .. controlId)
    end
end

-- Repaint the visualizer periodically
local repaintCounter = 0
local REPAINT_INTERVAL = 5  -- Every 5 timer ticks (100ms at 50Hz)

function timer.onTick()
    if not lfo.enabled then
        return
    end
    
    -- Calculate and send LFO value
    local output = calculateLFO()
    midi.sendControlChange(PORT_1, lfo.targetChannel, lfo.targetCC, output)
    
    -- Advance phase
    advancePhase()
    
    -- Repaint visualizer less frequently (for performance)
    repaintCounter = repaintCounter + 1
    if repaintCounter >= REPAINT_INTERVAL then
        repaintCounter = 0
        -- If you have a visualizer control, repaint it here
        -- local vizControl = controls.get(VISUALIZER_CONTROL_ID)
        -- if vizControl then vizControl:repaint() end
    end
end

-- PRESET INITIALIZATION
-- ============================================================================

function preset.onReady()
    print("MIDI LFO preset ready")
    
    -- Initialize timer at 50Hz (20ms period)
    timer.setPeriod(TIMER_PERIOD_MS)
    
    -- Create waveform overlay for list control
    overlays.create(1, {
        {value = 0, label = "Sine"},
        {value = 1, label = "Triangle"},
        {value = 2, label = "Saw Up"},
        {value = 3, label = "Square"},
        {value = 4, label = "Random"}
    })
    
    -- Setup visualizer if you have a Custom control for it
    -- setupVisualizer(YOUR_CUSTOM_CONTROL_ID)
    
    info.setText("LFO Ready")
end

-- ============================================================================
-- PRESET SETUP GUIDE:
-- 
-- Create these controls in the Preset Editor:
-- 1. PAD "Enable" - Function: enableLFO
-- 2. FADER "Rate" - Function: setLFORate, Formatter: formatLFORate
-- 3. FADER "Depth" - Function: setLFODepth
-- 4. LIST "Wave" - Function: setLFOWaveform, Overlay ID: 1
-- 5. FADER "Target CC" - Function: setLFOTargetCC, Min: 0, Max: 127
-- 6. FADER "Center" - Function: setLFOCenter, Default: 64
-- 7. (Optional) CUSTOM "Display" - for waveform visualization
--
-- All controls should use Device ID 1 (or create a virtual device)
-- ============================================================================
</file>

<file path="LICENSE">
MIT License

Copyright (c) 2026 Johnny Clem

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
</file>

<file path="mac/Sources/ElectraKit/MIDITransport.swift">
import CoreMIDI
import Foundation

public enum E1Error: Error, CustomStringConvertible {
    case notConnected
    case notFound
    case timeout
    case nack
    case empty
    case midi(OSStatus, String)
    case decode(String)

    public var description: String {
        switch self {
        case .notConnected:        return "Not connected to the Electra One."
        case .notFound:            return "Electra One not found — is it plugged in?"
        case .timeout:             return "Timeout — device did not respond."
        case .nack:                return "Device rejected the command (NACK)."
        case .empty:               return "Slot is empty."
        case .midi(let s, let m):  return "MIDI error (\(s)): \(m)"
        case .decode(let m):       return "Decode error: \(m)"
        }
    }
}

public struct PortNames: Sendable {
    public let input: String
    public let output: String
}

/// CoreMIDI transport for the Electra One.
///
/// Mirrors lib/transport.js: one persistent client/port pair, SysEx exchanges
/// serialized by the owning `E1Device` actor, fragmented responses reassembled
/// until EOX. Large uploads are sent in a single packet list (CoreMIDI splits
/// them on the wire); the device reassembles.
public final class MIDITransport: @unchecked Sendable {
    private var client = MIDIClientRef()
    private var inPort = MIDIPortRef()
    private var outPort = MIDIPortRef()
    private var source = MIDIEndpointRef()
    private var dest = MIDIEndpointRef()

    public private(set) var connected = false
    public private(set) var portNames: PortNames?

    private let lock = NSLock()
    private var buffer: [UInt8] = []
    private var waiter: ((E1Proto.Message) -> Void)?

    public init() {}

    // ── Discovery ───────────────────────────────────────────────────────────

    private static func displayName(_ endpoint: MIDIEndpointRef) -> String {
        var cf: Unmanaged<CFString>?
        let st = MIDIObjectGetStringProperty(endpoint, kMIDIPropertyDisplayName, &cf)
        guard st == noErr, let name = cf?.takeRetainedValue() else { return "" }
        return name as String
    }

    private static func score(_ name: String) -> Int {
        guard name.contains("Electra") else { return -1 }
        if name.contains("CTRL")    { return 3 }
        if name.contains("PORT 3")  { return 2 }
        if name.contains("MIDIIN3") { return 2 }
        return 1
    }

    public static func listPorts() -> (inputs: [String], outputs: [String]) {
        let ins = (0..<MIDIGetNumberOfSources()).map { displayName(MIDIGetSource($0)) }
        let outs = (0..<MIDIGetNumberOfDestinations()).map { displayName(MIDIGetDestination($0)) }
        return (ins, outs)
    }

    private func bestSource() -> (MIDIEndpointRef, String)? {
        var best: (MIDIEndpointRef, String, Int)?
        for i in 0..<MIDIGetNumberOfSources() {
            let ep = MIDIGetSource(i)
            let name = MIDITransport.displayName(ep)
            let s = MIDITransport.score(name)
            if s >= 0, best == nil || s > best!.2 { best = (ep, name, s) }
        }
        return best.map { ($0.0, $0.1) }
    }

    private func bestDest() -> (MIDIEndpointRef, String)? {
        var best: (MIDIEndpointRef, String, Int)?
        for i in 0..<MIDIGetNumberOfDestinations() {
            let ep = MIDIGetDestination(i)
            let name = MIDITransport.displayName(ep)
            let s = MIDITransport.score(name)
            if s >= 0, best == nil || s > best!.2 { best = (ep, name, s) }
        }
        return best.map { ($0.0, $0.1) }
    }

    // ── Lifecycle ───────────────────────────────────────────────────────────

    @discardableResult
    public func connect() throws -> PortNames {
        if connected, let p = portNames { return p }

        var c = MIDIClientRef()
        var st = MIDIClientCreateWithBlock("ElectraOne" as CFString, &c, nil)
        guard st == noErr else { throw E1Error.midi(st, "MIDIClientCreate") }
        client = c

        var ip = MIDIPortRef()
        st = MIDIInputPortCreateWithBlock(client, "ElectraOneIn" as CFString, &ip) { [weak self] listPtr, _ in
            self?.receive(listPtr)
        }
        guard st == noErr else { throw E1Error.midi(st, "MIDIInputPortCreate") }
        inPort = ip

        var op = MIDIPortRef()
        st = MIDIOutputPortCreate(client, "ElectraOneOut" as CFString, &op)
        guard st == noErr else { throw E1Error.midi(st, "MIDIOutputPortCreate") }
        outPort = op

        guard let (src, srcName) = bestSource(), let (dst, dstName) = bestDest() else {
            throw E1Error.notFound
        }
        source = src
        dest = dst

        st = MIDIPortConnectSource(inPort, source, nil)
        guard st == noErr else { throw E1Error.midi(st, "MIDIPortConnectSource") }

        let names = PortNames(input: srcName, output: dstName)
        portNames = names
        connected = true
        return names
    }

    public func disconnect() {
        if source != 0 { MIDIPortDisconnectSource(inPort, source) }
        if inPort != 0 { MIDIPortDispose(inPort) }
        if outPort != 0 { MIDIPortDispose(outPort) }
        if client != 0 { MIDIClientDispose(client) }
        inPort = 0; outPort = 0; client = 0; source = 0; dest = 0
        connected = false
        lock.lock(); buffer = []; waiter = nil; lock.unlock()
    }

    // ── Receive + reassembly ────────────────────────────────────────────────

    private func receive(_ listPtr: UnsafePointer<MIDIPacketList>) {
        for pkt in listPtr.unsafeSequence() {
            let len = Int(pkt.pointee.length)
            let bytes = withUnsafeBytes(of: pkt.pointee.data) { Array($0.prefix(len)) }
            feed(bytes)
        }
    }

    private func feed(_ bytes: [UInt8]) {
        var deliver: ((E1Proto.Message) -> Void)?
        var message: E1Proto.Message?

        lock.lock()
        if bytes.first == E1Proto.sox {
            buffer = bytes
        } else if !buffer.isEmpty {
            buffer += bytes
        } else {
            lock.unlock()
            return
        }
        if buffer.last == E1Proto.eox {
            let complete = buffer
            buffer = []
            message = E1Proto.classify(complete)
            deliver = waiter
        }
        lock.unlock()

        if let d = deliver, let m = message { d(m) }
    }

    // ── Send ────────────────────────────────────────────────────────────────

    private func send(_ bytes: [UInt8]) throws {
        guard connected else { throw E1Error.notConnected }
        let listSize = bytes.count + 128
        let raw = UnsafeMutableRawPointer.allocate(
            byteCount: listSize,
            alignment: MemoryLayout<MIDIPacketList>.alignment)
        defer { raw.deallocate() }
        let listPtr = raw.assumingMemoryBound(to: MIDIPacketList.self)

        let packet = MIDIPacketListInit(listPtr)
        let added: UnsafeMutablePointer<MIDIPacket>? = bytes.withUnsafeBufferPointer { buf in
            MIDIPacketListAdd(listPtr, listSize, packet, 0, bytes.count, buf.baseAddress!)
        }
        guard added != nil else { throw E1Error.midi(-1, "packet list overflow") }

        let st = MIDISend(outPort, dest, listPtr)
        guard st == noErr else { throw E1Error.midi(st, "MIDISend") }
    }

    // ── Exchanges ───────────────────────────────────────────────────────────
    //
    // The owning E1Device actor guarantees one exchange at a time, so a single
    // `waiter` slot is sufficient.

    /// Send a request and await the first `data` response.
    public func query(_ bytes: [UInt8], timeout: TimeInterval = 6) async throws -> (resource: UInt8, payload: [UInt8]) {
        try await withCheckedThrowingContinuation { cont in
            let state = ResumeOnce()
            let finish: (Result<(resource: UInt8, payload: [UInt8]), Error>) -> Void = { result in
                guard state.tryResume() else { return }
                self.lock.lock(); self.waiter = nil; self.lock.unlock()
                cont.resume(with: result)
            }
            lock.lock()
            waiter = { msg in
                if case let .data(resource, payload) = msg {
                    finish(.success((resource: resource, payload: payload)))
                }
            }
            lock.unlock()
            scheduleTimeout(timeout) { finish(.failure(E1Error.timeout)) }
            do { try send(bytes) } catch { finish(.failure(error)) }
        }
    }

    /// Send a command and await ACK (resolve) or NACK (throw).
    public func command(_ bytes: [UInt8], timeout: TimeInterval = 6) async throws {
        try await withCheckedThrowingContinuation { (cont: CheckedContinuation<Void, Error>) in
            let state = ResumeOnce()
            let finish: (Result<Void, Error>) -> Void = { result in
                guard state.tryResume() else { return }
                self.lock.lock(); self.waiter = nil; self.lock.unlock()
                cont.resume(with: result)
            }
            lock.lock()
            waiter = { msg in
                switch msg {
                case .ack:  finish(.success(()))
                case .nack: finish(.failure(E1Error.nack))
                default:    break // ignore notifications/data; keep waiting
                }
            }
            lock.unlock()
            scheduleTimeout(timeout) { finish(.failure(E1Error.timeout)) }
            do { try send(bytes) } catch { finish(.failure(error)) }
        }
    }

    private func scheduleTimeout(_ seconds: TimeInterval, _ fire: @escaping () -> Void) {
        DispatchQueue.global().asyncAfter(deadline: .now() + seconds, execute: fire)
    }
}

/// One-shot guard so a continuation resumes exactly once.
private final class ResumeOnce: @unchecked Sendable {
    private let lock = NSLock()
    private var done = false
    func tryResume() -> Bool {
        lock.lock(); defer { lock.unlock() }
        if done { return false }
        done = true
        return true
    }
}
</file>

<file path="mac/Sources/ElectraKit/Models.swift">
import Foundation

/// Hardware/firmware info returned by the device. Extra keys are ignored.
public struct DeviceInfo: Codable, Sendable {
    public var model: String?
    public var hwRevision: String?
    public var versionText: String?
    public var serial: String?

    public var modelUpper: String { (model ?? "?").uppercased() }
}

/// Lightweight summary of a preset, parsed for display without modelling the
/// full Electra schema.
public struct PresetSummary: Sendable {
    public var name: String
    public var version: Int?
    public var projectId: String?
    public var pages: Int
    public var controls: Int
    public var devices: Int
    public var deviceNames: [String]
}

public enum SlotStatus: String, Sendable {
    case unknown, scanning, ok, empty, error
}

public struct SlotState: Identifiable, Sendable, Equatable {
    public var slot: Int
    public var status: SlotStatus
    public var name: String?
    public var error: String?

    public var id: Int { slot }

    public init(slot: Int, status: SlotStatus, name: String? = nil, error: String? = nil) {
        self.slot = slot
        self.status = status
        self.name = name
        self.error = error
    }
}
</file>

<file path="mac/Sources/ElectraKit/ProjectImport.swift">
import Foundation

/// Loading Electra files, auto-detecting the two formats:
///   - `.eproj` — the web-editor *project* (schemaVersion 2): controls live in
///     `tiles`, positioned by `slotId`, with an embedded `lua` script.
///   - `.epr` / `.json` — the *device preset*: controls in `controls` with
///     pixel `bounds`, the format the hardware exchanges.
///
/// Projects are converted into the device-preset model so the visual editor
/// and device upload work uniformly.
extension PresetDocument {

    /// Load from a file's text, auto-detecting project vs preset.
    public static func load(fileText text: String) -> PresetDocument? {
        guard let data = text.data(using: .utf8),
              let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else { return nil }

        if obj["tiles"] != nil || obj["schemaVersion"] != nil {
            return importProject(obj)
        }
        return PresetDocument(root: obj)
    }

    /// True if the JSON text looks like an Electra project (.eproj).
    public static func isProject(_ text: String) -> Bool {
        guard let data = text.data(using: .utf8),
              let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else { return false }
        return obj["tiles"] != nil || obj["schemaVersion"] != nil
    }

    // ── Project → preset conversion ─────────────────────────────────────────

    static func importProject(_ proj: [String: Any]) -> PresetDocument {
        let pagesIn = proj["pages"] as? [[String: Any]] ?? [["id": 1, "name": "Page 1"]]
        let pageIds = pagesIn.compactMap { $0["id"] as? Int }
        func pageId(forSlot slot: Int) -> Int {
            let idx = (slot - 1) / 36
            return (idx >= 0 && idx < pageIds.count) ? pageIds[idx] : (pageIds.first ?? 1)
        }

        let tiles = proj["tiles"] as? [[String: Any]] ?? []
        var controls: [[String: Any]] = []
        for (i, tile) in tiles.enumerated() {
            let slotId = tile["slotId"] as? Int ?? (i + 1)
            let within = (slotId - 1) % 36
            let col = within % 6
            let row = within / 6
            let controlSetId = row / 2 + 1          // 6 rows → 3 control sets
            let potId = (row % 2) * 6 + col + 1     // 1…12 within the control set
            let refId = tile["reference"] as? Int ?? (i + 1)

            var control: [String: Any] = [
                "id": refId,
                "type": tile["type"] as? String ?? "fader",
                "name": tile["name"] as? String ?? "",
                "color": tile["color"] as? String ?? "FFFFFF",
                "bounds": slotBounds(col: col, row: row),
                "pageId": pageId(forSlot: slotId),
                "controlSetId": controlSetId,
                "visible": tile["visible"] as? Bool ?? true,
                "inputs": [["potId": potId, "valueId": "value"]],
            ]
            if let v = tile["variant"] as? String, !v.isEmpty { control["variant"] = v }
            if let m = tile["mode"] as? String { control["mode"] = m }

            var values = tile["values"] as? [[String: Any]] ?? []
            for j in values.indices where values[j]["id"] == nil { values[j]["id"] = "value" }
            control["values"] = values

            controls.append(control)
        }

        let devicesIn = proj["devices"] as? [[String: Any]] ?? []
        let devices: [[String: Any]] = devicesIn.isEmpty
            ? [["id": 1, "name": "MIDI Device 1", "port": 1, "channel": 1]]
            : devicesIn.map { d in
                [
                    "id": d["id"] ?? 1,
                    "name": d["name"] ?? "Device",
                    "port": d["port"] ?? 1,
                    "channel": d["channel"] ?? 1,
                ]
            }

        let root: [String: Any] = [
            "version": 2,
            "name": proj["name"] as? String ?? "Imported Preset",
            "projectId": proj["id"] as? String ?? PresetDocument.newPreset().projectId ?? "imported",
            "pages": pagesIn.map { ["id": $0["id"] ?? 1, "name": $0["name"] ?? "Page"] },
            "devices": devices,
            "groups": [[String: Any]](),
            "overlays": [[String: Any]](),
            "controls": controls,
        ]

        var doc = PresetDocument(root: root)
        if let lua = proj["lua"] as? String, !lua.isEmpty { doc.lua = lua }
        return doc
    }

    /// Pixel bounds for a 6×6 grid cell, approximating the Electra layout.
    static func slotBounds(col: Int, row: Int) -> [Int] {
        let leftMargin = 12.0, topMargin = 22.0, bottom = 8.0
        let colW = (screenWidth - leftMargin * 2) / 6
        let rowH = (screenHeight - topMargin - bottom) / 6
        let padX = 7.0, padY = 8.0
        let x = leftMargin + Double(col) * colW + padX
        let y = topMargin + Double(row) * rowH + padY
        let w = colW - padX * 2
        let h = rowH - padY * 2
        return [Int(x.rounded()), Int(y.rounded()), Int(w.rounded()), Int(h.rounded())]
    }
}
</file>

<file path="mac/build-app.sh">
#!/bin/bash
# Build ElectraOne.app — a double-clickable macOS app bundle.
#
# Usage: ./build-app.sh            (release build into ./ElectraOne.app)
#        open ./ElectraOne.app     (launch it)
set -euo pipefail

cd "$(dirname "$0")"

CONFIG="${1:-release}"
APP="ElectraOne.app"
BUNDLE_ID="one.electra.companion"

echo "▶ swift build -c $CONFIG"
swift build -c "$CONFIG" --product ElectraOneApp

BIN="$(swift build -c "$CONFIG" --product ElectraOneApp --show-bin-path)/ElectraOneApp"

echo "▶ assembling $APP"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$BIN" "$APP/Contents/MacOS/ElectraOne"

cat > "$APP/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key>            <string>Electra One</string>
    <key>CFBundleDisplayName</key>     <string>Electra One</string>
    <key>CFBundleIdentifier</key>      <string>$BUNDLE_ID</string>
    <key>CFBundleVersion</key>         <string>1</string>
    <key>CFBundleShortVersionString</key><string>0.1.0</string>
    <key>CFBundlePackageType</key>     <string>APPL</string>
    <key>CFBundleExecutable</key>      <string>ElectraOne</string>
    <key>LSMinimumSystemVersion</key>  <string>13.0</string>
    <key>NSHighResolutionCapable</key> <true/>
    <key>LSApplicationCategoryType</key><string>public.app-category.music</string>
</dict>
</plist>
PLIST

# Ad-hoc sign so Gatekeeper lets it run locally.
codesign --force --deep --sign - "$APP" >/dev/null 2>&1 || echo "  (codesign skipped)"

echo "✓ built $APP"
echo "  launch with:  open $(pwd)/$APP"
</file>

<file path="mac/Package.swift">
// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "ElectraOne",
    platforms: [.macOS(.v13)],
    targets: [
        // Shared core: MIDI transport, SysEx protocol, high-level device ops.
        .target(
            name: "ElectraKit"
        ),
        // The SwiftUI Mac app.
        .executableTarget(
            name: "ElectraOneApp",
            dependencies: ["ElectraKit"]
        ),
        // Headless probe used to verify CoreMIDI talks to the hardware.
        .executableTarget(
            name: "e1probe",
            dependencies: ["ElectraKit"]
        ),
    ],
    swiftLanguageModes: [.v5]
)
</file>

<file path="tui/app.mjs">
// tui/app.mjs
//
// Full-screen terminal app for the Electra One.
//
// Auto-connects to a USB-attached Electra One, lists preset slots in a bank,
// and lets you view / pull / edit / upload / activate presets — all over the
// persistent MIDI connection in lib/transport.js.
//
// No build step: Ink + React rendered through `htm` tagged templates.

import React, { useState, useEffect, useRef, useCallback } from 'react';
import { render, Box, Text, useApp, useInput, useStdin } from 'ink';
import htm from 'htm';
import { spawn } from 'node:child_process';
import { writeFileSync, readFileSync, mkdtempSync } from 'node:fs';
import { tmpdir } from 'node:os';
import path from 'node:path';
import { createRequire } from 'node:module';

const require = createRequire(import.meta.url);
const device    = require('../lib/device');
const transport = require('../lib/transport');

const html = htm.bind(React.createElement);

const SLOTS_PER_BANK = 12;
const BANKS = 6;
const SCAN_TIMEOUT = 1500;

const safeName = (name) =>
  (name || 'preset').trim().replace(/[^a-z0-9_\-. ]/gi, '_').replace(/\s+/g, '_').slice(0, 60);

// ── Slot list ─────────────────────────────────────────────────────────────────

function SlotRow({ slot, cursor }) {
  const selected = slot.slot === cursor;
  const marker = selected ? '▶' : ' ';
  let label, color;
  switch (slot.status) {
    case 'ok':       label = slot.name;          color = 'green';   break;
    case 'empty':    label = '—';                color = 'gray';    break;
    case 'scanning': label = 'scanning…';        color = 'yellow';  break;
    case 'error':    label = `(${slot.error})`;  color = 'red';     break;
    default:         label = '·';                color = 'gray';    break;
  }
  return html`
    <${Box}>
      <${Text} color=${selected ? 'cyan' : undefined} bold=${selected}>
        ${marker} [${String(slot.slot).padStart(2, '0')}] ${'  '}
      <//>
      <${Text} color=${color}>${label}<//>
    <//>
  `;
}

// ── Detail pane ─────────────────────────────────────────────────────────────────

function Detail({ detail, loading }) {
  if (loading) {
    return html`<${Box} flexDirection="column"><${Text} color="yellow">Loading preset…<//><//>`;
  }
  if (!detail) {
    return html`
      <${Box} flexDirection="column">
        <${Text} dimColor>Select a slot and press <${Text} color="cyan">Enter<//> to view it.<//>
      <//>`;
  }
  if (detail.empty) {
    return html`<${Box}><${Text} dimColor>Slot ${detail.slot} is empty.<//><//>`;
  }
  const p = detail.preset;
  const pages = p.pages?.length ?? 0;
  const controls = p.controls?.length ?? 0;
  const devices = p.devices?.length ?? 0;
  return html`
    <${Box} flexDirection="column">
      <${Text} bold color="green">${p.name || '(unnamed)'}<//>
      <${Text} dimColor>slot ${detail.slot} · v${p.version ?? '?'}${p.projectId ? ` · ${p.projectId}` : ''}<//>
      <${Box} marginTop=${1} flexDirection="column">
        <${Text}>Pages    : ${pages}<//>
        <${Text}>Controls : ${controls}<//>
        <${Text}>Devices  : ${devices}<//>
      <//>
      ${devices > 0 && html`
        <${Box} marginTop=${1} flexDirection="column">
          <${Text} dimColor>Devices:<//>
          ${p.devices.slice(0, 6).map((d, i) => html`
            <${Text} key=${i}>  • ${d.name || d.id || '?'}${d.port != null ? ` (port ${d.port})` : ''}<//>
          `)}
        <//>`}
    <//>
  `;
}

// ── Inline text prompt (for upload path) ────────────────────────────────────────

function Prompt({ label, value }) {
  return html`
    <${Box}>
      <${Text} color="cyan">${label} <//>
      <${Text}>${value}<//>
      <${Text} inverse> <//>
    <//>
  `;
}

// ── Main app ─────────────────────────────────────────────────────────────────

function App() {
  const { exit } = useApp();
  const { setRawMode } = useStdin();

  const [status, setStatus]   = useState('connecting'); // connecting|ready|error
  const [info, setInfo]       = useState(null);
  const [portName, setPort]   = useState('');
  const [errorMsg, setError]  = useState('');

  const [bank, setBank]       = useState(0);
  const [slots, setSlots]     = useState(() => freshSlots());
  const [cursor, setCursor]   = useState(0);

  const [detail, setDetail]   = useState(null);
  const [detailLoading, setDetailLoading] = useState(false);

  const [busy, setBusy]       = useState(false);
  const [message, setMessage] = useState('');

  const [mode, setMode]       = useState('browse'); // browse | upload
  const [input, setInput]     = useState('');

  const scanToken = useRef(0); // cancels stale scans on bank change/refresh

  function freshSlots() {
    return Array.from({ length: SLOTS_PER_BANK }, (_, slot) => ({ slot, status: 'unknown' }));
  }

  // Connect once on mount.
  useEffect(() => {
    let cancelled = false;
    (async () => {
      try {
        const ports = transport.connect();
        if (cancelled) return;
        setPort(ports.inputName || '');
        const i = await device.getInfo();
        if (cancelled) return;
        setInfo(i);
        setStatus('ready');
      } catch (e) {
        if (!cancelled) { setError(e.message); setStatus('error'); }
      }
    })();
    return () => { cancelled = true; };
  }, []);

  // (Re)scan whenever the bank changes (and once we're ready).
  const rescan = useCallback((targetBank) => {
    const token = ++scanToken.current;
    setSlots(freshSlots());
    setDetail(null);
    (async () => {
      await device.scanSlots({
        bank: targetBank,
        slotCount: SLOTS_PER_BANK,
        timeoutMs: SCAN_TIMEOUT,
        onSlot: (r) => {
          if (token !== scanToken.current) return; // a newer scan started
          setSlots((prev) => {
            const next = prev.slice();
            next[r.slot] = { slot: r.slot, status: r.status, name: r.name, error: r.error };
            return next;
          });
        },
      });
      if (token === scanToken.current) setMessage(`Scanned bank ${targetBank}.`);
    })();
  }, []);

  useEffect(() => {
    if (status === 'ready') rescan(bank);
  }, [status, bank, rescan]);

  // ── Operations ──────────────────────────────────────────────────────────────

  const current = slots[cursor];

  const withBusy = async (msg, fn) => {
    setBusy(true);
    setMessage(msg);
    try {
      const done = await fn();
      setMessage(done || 'Done.');
    } catch (e) {
      setMessage(`Error: ${e.message}`);
    } finally {
      setBusy(false);
    }
  };

  const loadDetail = useCallback(async (slot) => {
    setDetailLoading(true);
    setDetail(null);
    try {
      const preset = await device.getPreset({ bank, slot });
      setDetail({ slot, preset });
      setMessage(`Loaded "${preset.name}".`);
    } catch (e) {
      if (device.isEmptySlot(e)) setDetail({ slot, empty: true });
      else setMessage(`Error: ${e.message}`);
    } finally {
      setDetailLoading(false);
    }
  }, [bank]);

  const pullToFile = (slot) => withBusy(`Pulling slot ${slot}…`, async () => {
    const preset = await device.getPreset({ bank, slot });
    const file = path.resolve(`${safeName(preset.name)}.json`);
    writeFileSync(file, JSON.stringify(preset, null, 2), 'utf8');
    return `Saved → ${file}`;
  });

  const activate = (slot) => withBusy(`Activating bank ${bank}, slot ${slot}…`, async () => {
    await device.switchSlot(bank, slot);
    return `Activated bank ${bank}, slot ${slot} on device.`;
  });

  const uploadFile = (slot, file) => withBusy(`Uploading ${file} → slot ${slot}…`, async () => {
    const preset = await device.pushPresetFromFile(file, { bank, slot });
    rescan(bank);
    return `Uploaded "${preset.name}" → bank ${bank}, slot ${slot}.`;
  });

  // Pull → open $EDITOR → push back on save.
  const editInEditor = (slot) => {
    const editor = process.env.VISUAL || process.env.EDITOR || 'vi';
    setBusy(true);
    setMessage(`Pulling slot ${slot} for editing…`);
    (async () => {
      let preset;
      try {
        preset = await device.getPreset({ bank, slot });
      } catch (e) {
        setBusy(false);
        setMessage(device.isEmptySlot(e) ? 'Slot is empty — nothing to edit.' : `Error: ${e.message}`);
        return;
      }
      const dir = mkdtempSync(path.join(tmpdir(), 'e1-edit-'));
      const file = path.join(dir, `${safeName(preset.name)}.json`);
      const before = JSON.stringify(preset, null, 2);
      writeFileSync(file, before, 'utf8');

      // Hand the terminal to the editor.
      setRawMode(false);
      await new Promise((resolve) => {
        const child = spawn(editor, [file], { stdio: 'inherit' });
        child.on('exit', resolve);
        child.on('error', () => resolve());
      });
      setRawMode(true);

      let edited;
      try {
        const after = readFileSync(file, 'utf8');
        if (after === before) { setBusy(false); setMessage('No changes — left slot untouched.'); return; }
        edited = JSON.parse(after);
      } catch (e) {
        setBusy(false);
        setMessage(`Invalid JSON after edit — not uploaded: ${e.message}`);
        return;
      }
      try {
        await device.putPreset(edited, { bank, slot });
        setMessage(`Saved edits → bank ${bank}, slot ${slot}.`);
        rescan(bank);
      } catch (e) {
        setMessage(`Upload failed: ${e.message}`);
      } finally {
        setBusy(false);
      }
    })();
  };

  // ── Input handling ────────────────────────────────────────────────────────────

  useInput((inputChar, key) => {
    if (mode === 'upload') {
      if (key.escape) { setMode('browse'); setInput(''); setMessage('Upload cancelled.'); return; }
      if (key.return) {
        const file = input.trim();
        setMode('browse'); setInput('');
        if (file) uploadFile(cursor, file);
        return;
      }
      if (key.backspace || key.delete) { setInput((s) => s.slice(0, -1)); return; }
      if (inputChar && !key.ctrl && !key.meta) setInput((s) => s + inputChar);
      return;
    }

    if (busy) return; // ignore keys during operations

    if (inputChar === 'q' || (key.ctrl && inputChar === 'c')) {
      transport.disconnect();
      exit();
      return;
    }
    if (key.upArrow || inputChar === 'k') { setCursor((c) => (c - 1 + SLOTS_PER_BANK) % SLOTS_PER_BANK); return; }
    if (key.downArrow || inputChar === 'j') { setCursor((c) => (c + 1) % SLOTS_PER_BANK); return; }
    if (key.return) { loadDetail(cursor); return; }
    if (inputChar === 'p') { pullToFile(cursor); return; }
    if (inputChar === 'e') { editInEditor(cursor); return; }
    if (inputChar === 's') { activate(cursor); return; }
    if (inputChar === 'u') { setMode('upload'); setInput(''); setMessage(''); return; }
    if (inputChar === 'r') { rescan(bank); return; }
    if (inputChar === ']' || inputChar === 'b') { setBank((b) => (b + 1) % BANKS); return; }
    if (inputChar === '[') { setBank((b) => (b - 1 + BANKS) % BANKS); return; }
  });

  // ── Render ────────────────────────────────────────────────────────────────────

  if (status === 'connecting') {
    return html`<${Box} padding=${1}><${Text} color="yellow">Connecting to Electra One…<//><//>`;
  }
  if (status === 'error') {
    return html`
      <${Box} flexDirection="column" padding=${1}>
        <${Text} color="red" bold>Could not connect to the Electra One.<//>
        <${Box} marginTop=${1}><${Text}>${errorMsg}<//><//>
        <${Box} marginTop=${1}><${Text} dimColor>Press q to quit.<//><//>
      <//>`;
  }

  return html`
    <${Box} flexDirection="column" padding=${1}>
      <!-- Header -->
      <${Box} justifyContent="space-between">
        <${Text} bold color="cyan">Electra One ${info ? info.model.toUpperCase() : ''} · fw ${info?.versionText ?? '?'}<//>
        <${Text} dimColor>${info?.serial ?? ''}<//>
      <//>
      <${Box}><${Text} dimColor>${portName}<//><//>

      <!-- Bank + body -->
      <${Box} marginTop=${1}>
        <${Text} bold>Bank ${bank}<//>
        <${Text} dimColor>  ([ / ] to change)<//>
      <//>
      <${Box} marginTop=${1}>
        <${Box} flexDirection="column" width=${30} marginRight=${2}>
          ${slots.map((s) => html`<${SlotRow} key=${s.slot} slot=${s} cursor=${cursor} />`)}
        <//>
        <${Box} flexDirection="column" flexGrow=${1} borderStyle="round" borderColor="gray" paddingX=${1}>
          <${Detail} detail=${detail} loading=${detailLoading} />
        <//>
      <//>

      <!-- Status line -->
      <${Box} marginTop=${1}>
        ${busy
          ? html`<${Text} color="yellow">⏳ ${message}<//>`
          : html`<${Text}>${message || ' '}<//>`}
      <//>

      <!-- Footer -->
      ${mode === 'upload'
        ? html`<${Box} marginTop=${1}><${Prompt} label="Upload JSON file path:" value=${input} /><//>`
        : html`
          <${Box} marginTop=${1}>
            <${Text} dimColor>
              ↑/↓ move · Enter view · ${'p'} pull · ${'e'} edit · ${'u'} upload · ${'s'} activate · ${'r'} rescan · ${'q'} quit
            <//>
          <//>`}
    <//>
  `;
}

export { App };

export function start() {
  // Ink needs a TTY for full-screen + input.
  if (!process.stdout.isTTY) {
    console.error('The TUI needs an interactive terminal (TTY).');
    process.exit(1);
  }
  const app = render(html`<${App} />`);
  return app.waitUntilExit();
}
</file>

<file path="tui/smoke.test.mjs">
// Smoke test: render the real App against the connected device (read-only),
// drive a few keypresses, and print captured frames. Not a unit test â€” a
// manual end-to-end render check that needs the hardware attached.
import React from 'react';
import { render } from 'ink-testing-library';
import htm from 'htm';
import { App } from './app.mjs';
import { createRequire } from 'node:module';

const require = createRequire(import.meta.url);
const transport = require('../lib/transport');
const html = htm.bind(React.createElement);

const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
const lastFrame = (inst) => inst.lastFrame();

(async () => {
  const inst = render(html`<${App} />`);

  await sleep(800);
  console.log('\nâ”€â”€â”€â”€ after connect â”€â”€â”€â”€');
  console.log(lastFrame(inst));

  // wait for scan to populate
  await sleep(6000);
  console.log('\nâ”€â”€â”€â”€ after scan â”€â”€â”€â”€');
  console.log(lastFrame(inst));

  // move down twice and view slot
  inst.stdin.write('j');
  inst.stdin.write('j');
  inst.stdin.write('\r'); // Enter -> view
  await sleep(2500);
  console.log('\nâ”€â”€â”€â”€ after viewing slot 2 â”€â”€â”€â”€');
  console.log(lastFrame(inst));

  // open upload prompt then cancel
  inst.stdin.write('u');
  await sleep(200);
  inst.stdin.write('/tmp/x.json');
  await sleep(200);
  console.log('\nâ”€â”€â”€â”€ upload prompt â”€â”€â”€â”€');
  console.log(lastFrame(inst));
  inst.stdin.write(''); // ESC cancel
  await sleep(300);

  inst.unmount();
  transport.disconnect();
  console.log('\nâœ“ smoke test completed without render crash');
  process.exit(0);
})().catch((e) => { console.error('SMOKE FAIL:', e); process.exit(1); });
</file>

<file path="package.json">
{
  "name": "e1cli",
  "version": "0.2.0",
  "description": "TUI + CLI for the Electra One — connect over USB MIDI to view, download, edit, and upload presets",
  "bin": {
    "e1": "./bin/e1.js"
  },
  "scripts": {
    "start": "node ./bin/e1.js tui",
    "tui": "node ./bin/e1.js tui"
  },
  "type": "commonjs",
  "engines": {
    "node": ">=18"
  },
  "dependencies": {
    "commander": "^12.0.0",
    "htm": "^3.1.1",
    "ink": "^5.2.1",
    "midi": "^2.0.0",
    "react": "^18.3.1"
  },
  "devDependencies": {
    "ink-testing-library": "^4.0.0"
  }
}
</file>

<file path="lib/protocol.js">
'use strict';

const SOX = 0xF0;
const EOX = 0xF7;
const MANUFACTURER = [0x00, 0x21, 0x45];

const OP = {
  UPLOAD:      0x01,
  REQUEST:     0x02,
  RESPONSE:    0x01,
  SELECT_SLOT: 0x14, // "set preset slot" — arms the target slot for upload
  ACK_NACK:    0x7E,
};

const RES = {
  PRESET:  0x01,
  LUA:     0x0C,
  INFO:    0x7F,
  RUNTIME: 0x7E,
};

function frame(...bytes) {
  return [SOX, ...MANUFACTURER, ...bytes, EOX];
}

const infoRequest    = () => frame(OP.REQUEST, RES.INFO);
const runtimeRequest = () => frame(OP.REQUEST, RES.RUNTIME);

function presetRequest(bank, slot) {
  if (bank != null && slot != null) return frame(OP.REQUEST, RES.PRESET, bank, slot);
  return frame(OP.REQUEST, RES.PRESET);
}

/**
 * Build a preset-upload SysEx message.
 *
 * IMPORTANT: the device always uploads to the *currently active* slot. There
 * is no bank/slot variant of the upload command — the JSON body follows the
 * resource byte directly. To target a specific slot, send presetSlotSelect()
 * first to arm it, then upload. (Earlier code inserted bank/slot bytes here,
 * which corrupted the JSON body and got a NACK.)
 */
function presetUpload(jsonStr) {
  const payload = Array.from(Buffer.from(jsonStr, 'ascii'));
  return [SOX, ...MANUFACTURER, OP.UPLOAD, RES.PRESET, ...payload, EOX];
}

/** "Set preset slot" — arm the given bank/slot as the active target. */
function presetSlotSelect(bank, slot) {
  return frame(OP.SELECT_SLOT, 0x08, bank, slot);
}

function luaRequest(bank, slot) {
  if (bank != null && slot != null) return frame(OP.REQUEST, RES.LUA, bank, slot);
  return frame(OP.REQUEST, RES.LUA);
}

function luaUpload(luaStr, bank, slot) {
  const payload = Array.from(Buffer.from(luaStr, 'ascii'));
  if (bank != null && slot != null)
    return [SOX, ...MANUFACTURER, OP.UPLOAD, RES.LUA, bank, slot, ...payload, EOX];
  return [SOX, ...MANUFACTURER, OP.UPLOAD, RES.LUA, ...payload, EOX];
}
/**
 * Acknowledgement codes carried in the byte after the 0x7E op.
 *
 * Empirically, an upload triggers two 0x7E messages from the device:
 *   F0 00 21 45 7E 05 F7          ← a notification (NOT a result)
 *   F0 00 21 45 7E 01 00 00 F7    ← the actual ACK
 *
 * The old code treated any 0x7E whose code byte wasn't 0x01 as a NACK, so the
 * leading 0x05 notification was misread as a rejection. We now decode the code
 * explicitly and ignore anything that isn't a definite ack/nack.
 */
const ACK = 0x01;
const NAK = 0x00;

function classify(msg) {
  if (
    msg[0] !== SOX  || msg[1] !== 0x00 ||
    msg[2] !== 0x21 || msg[3] !== 0x45 ||
    msg.at(-1) !== EOX
  ) return { type: 'unknown' };

  const op = msg[4];
  if (op === OP.RESPONSE) return { type: 'data', resource: msg[5], payload: msg.slice(6, -1) };
  if (op === OP.ACK_NACK) {
    const code = msg[5];
    if (code === ACK) return { type: 'ack' };
    if (code === NAK) return { type: 'nack' };
    return { type: 'status', code }; // e.g. 0x05 notification — wait for the real ack/nack
  }
  return { type: 'unknown' };
}

function decodeJSON(payload) {
  try {
    return JSON.parse(Buffer.from(payload).toString('ascii'));
  } catch (e) {
    throw new Error(`Malformed JSON in device response: ${e.message}`);
  }
}

function decodeText(payload) {
  return Buffer.from(payload).toString('ascii');
}

module.exports = {
  SOX, 
  EOX, 
  MANUFACTURER, 
  OP, 
  RES,
  frame, 
  infoRequest, 
  runtimeRequest,
  presetRequest, 
  presetUpload, 
  presetSlotSelect, 
  luaRequest, 
  luaUpload, 
  classify, 
  decodeJSON, 
  decodeText,
};
</file>

<file path="lib/transport.js">
'use strict';

/**
 * transport.js
 *
 * MIDI I/O: port discovery, send, receive.
 * No Electra One protocol knowledge here — just byte transport.
 *
 * Connection model (v2 — persistent):
 *
 *   The previous version opened and closed the CoreMIDI ports on *every*
 *   query/command via a `withPorts` wrapper. On macOS this crashes libuv
 *   after a handful of operations:
 *
 *       Assertion failed: (handle->flags & UV_HANDLE_CLOSING),
 *       function uv__finish_close, file core.c
 *
 *   Repeatedly opening/closing the same node-midi handle (and adding/removing
 *   listeners) confuses libuv's close bookkeeping. The fix is to open the
 *   ports ONCE (connect) and keep them open for the life of the process,
 *   reusing a single persistent 'message' listener. A TUI needs exactly this
 *   persistent session anyway.
 *
 *   Requests are serialized through an internal queue so only one SysEx
 *   exchange is in flight at a time, matching how the device responds.
 *
 * Still handled from v1:
 *
 *   - CoreMIDI -304 (kMIDIClientCreateErr): one shared Input/Output pair for
 *     the whole process, used for both enumeration and I/O.
 *   - SysEx fragmentation: CoreMIDI splits large payloads across multiple
 *     'message' events; we reassemble until EOX (0xF7).
 */

const midi    = require('midi');
const { classify, SOX, EOX } = require('./protocol');

// ── Shared MIDI client (singleton) ────────────────────────────────────────────

let _input  = null;
let _output = null;

/**
 * Return the shared Input/Output pair, creating it on first call.
 * Reusing these objects avoids registering multiple CoreMIDI clients.
 */
function getShared() {
  if (!_input) {
    _input  = new midi.Input();
    _output = new midi.Output();
    _input.ignoreTypes(false, false, false); // never filter SysEx
  }
  return { input: _input, output: _output };
}

// ── Port enumeration ──────────────────────────────────────────────────────────

/**
 * List all available MIDI port names.
 * Uses the shared MIDI objects — no extra CoreMIDI clients created.
 * @returns {{ inputs: string[], outputs: string[] }}
 */
function listAllPorts() {
  const { input, output } = getShared();
  const inputs  = Array.from({ length: input.getPortCount()  }, (_, i) => input.getPortName(i));
  const outputs = Array.from({ length: output.getPortCount() }, (_, i) => output.getPortName(i));
  return { inputs, outputs };
}

/**
 * Score a port name for likelihood of being the Electra One CTRL port.
 * Higher is better; -1 = not E1.
 * @param {string} name
 * @returns {number}
 */
function scorePort(name) {
  if (!name.includes('Electra')) return -1;
  if (name.includes('CTRL'))     return 3;  // preferred management port
  if (name.includes('PORT 3'))   return 2;  // Linux alias
  if (name.includes('MIDIIN3'))  return 2;  // Windows alias
  return 1;
}

/**
 * Find the best Electra One input and output port indices.
 * @returns {{ inputPort: number, outputPort: number, inputName: string|null, outputName: string|null }}
 */
function findE1Ports() {
  const { inputs, outputs } = listAllPorts();
  const best = (names) =>
    names.reduce((b, name, i) => scorePort(name) > scorePort(names[b] ?? '') ? i : b, -1);

  const inputPort  = best(inputs);
  const outputPort = best(outputs);
  return {
    inputPort,
    outputPort,
    inputName:  inputs[inputPort]   ?? null,
    outputName: outputs[outputPort] ?? null,
  };
}

// ── SysEx accumulator ─────────────────────────────────────────────────────────

/**
 * Create a stateful accumulator that reassembles fragmented SysEx messages.
 *
 * CoreMIDI can split large SysEx payloads across multiple `message` events.
 * Each call to feed(bytes) appends to an internal buffer. When EOX (0xF7) is
 * seen, feed returns the complete assembled message and resets. Returns null
 * while still accumulating.
 *
 * @returns {(bytes: number[]) => number[]|null}
 */
function makeSysExAccumulator() {
  let buf = [];
  return function feed(bytes) {
    if (bytes[0] === SOX) {
      buf = [...bytes];           // new message — reset
    } else if (buf.length > 0) {
      buf = buf.concat(bytes);    // continuation fragment
    } else {
      return null;                // non-SysEx with no active buffer — ignore
    }

    if (buf[buf.length - 1] === EOX) {
      const complete = buf;
      buf = [];
      return complete;
    }

    return null; // still accumulating
  };
}

// ── Persistent connection ─────────────────────────────────────────────────────

let _connected   = false;
let _onComplete   = null;          // current waiter for a complete SysEx message
let _queue        = Promise.resolve(); // serializes exchanges
let _portNames    = { inputName: null, outputName: null };

/**
 * Open the Electra One ports and attach the persistent message listener.
 * Idempotent — calling again while connected is a no-op.
 *
 * @returns {{ inputName: string, outputName: string }}
 */
function connect() {
  if (_connected) return _portNames;

  const { inputPort, outputPort, inputName, outputName } = findE1Ports();
  if (inputPort === -1 || outputPort === -1) {
    throw new Error(
      'Electra One not found — is it plugged in?\n' +
      'Run `e1 ports` to list available MIDI ports.'
    );
  }

  const { input, output } = getShared();
  input.openPort(inputPort);
  output.openPort(outputPort);

  const feed = makeSysExAccumulator();
  input.on('message', (_dt, msg) => {
    const complete = feed(Array.from(msg));
    if (!complete) return;            // still accumulating a fragmented message
    if (_onComplete) _onComplete(classify(complete));
  });

  _connected = true;
  _portNames = { inputName, outputName };
  return _portNames;
}

/**
 * Close the ports and detach listeners. Safe to call when not connected.
 */
function disconnect() {
  if (!_connected) return;
  try { _input.removeAllListeners('message'); } catch {}
  try { _input.closePort();  } catch {}
  try { _output.closePort(); } catch {}
  _connected = false;
  _onComplete = null;
}

/** @returns {boolean} */
function isConnected() {
  return _connected;
}

// ── Send and receive ──────────────────────────────────────────────────────────

/**
 * Send a SysEx message, then resolve the first complete response for which
 * `match(parsed)` returns a non-undefined value. Returning an Error rejects;
 * any other value resolves. Returning undefined keeps waiting.
 *
 * Only one exchange runs at a time (callers go through the serializing queue).
 *
 * @param {number[]} msgBytes
 * @param {(parsed: object) => any} match
 * @param {number} timeoutMs
 * @param {string} timeoutMessage
 * @returns {Promise<any>}
 */
function _exchange(msgBytes, match, timeoutMs, timeoutMessage) {
  return new Promise((resolve, reject) => {
    let settled = false;
    let timer;

    const settle = (err, result) => {
      if (settled) return;
      settled = true;
      clearTimeout(timer);
      _onComplete = null;
      if (err) reject(err); else resolve(result);
    };

    _onComplete = (parsed) => {
      const r = match(parsed);
      if (r === undefined) return;            // not what we're waiting for
      if (r instanceof Error) settle(r);
      else settle(null, r);
    };

    timer = setTimeout(() => settle(new Error(timeoutMessage)), timeoutMs);

    try {
      _output.sendMessage(msgBytes);
    } catch (e) {
      settle(e);
    }
  });
}

/**
 * Enqueue an exchange so exchanges run strictly one at a time.
 * @template T
 * @param {() => Promise<T>} fn
 * @returns {Promise<T>}
 */
function _enqueue(fn) {
  const run = _queue.then(fn, fn);
  _queue = run.then(() => {}, () => {}); // never let a rejection break the chain
  return run;
}

/**
 * Send a SysEx message and wait for a complete data response.
 * Auto-connects on first use. Handles fragmented responses transparently.
 *
 * @param {number[]} msgBytes
 * @param {object}  [opts]
 * @param {number}  [opts.timeoutMs=6000]
 * @returns {Promise<{ resource: number, payload: number[] }>}
 */
function query(msgBytes, { timeoutMs = 6000 } = {}) {
  return _enqueue(() => {
    if (!_connected) connect();
    return _exchange(
      msgBytes,
      (parsed) => (parsed.type === 'data'
        ? { resource: parsed.resource, payload: parsed.payload }
        : undefined),
      timeoutMs,
      'Timeout — device did not respond'
    );
  });
}

/**
 * Send a SysEx command and wait for ACK or NACK.
 * Resolves on ACK, rejects on NACK or timeout. Auto-connects on first use.
 *
 * @param {number[]} msgBytes
 * @param {object}  [opts]
 * @param {number}  [opts.timeoutMs=6000]
 * @returns {Promise<void>}
 */
function command(msgBytes, { timeoutMs = 6000 } = {}) {
  return _enqueue(() => {
    if (!_connected) connect();
    return _exchange(
      msgBytes,
      (parsed) => {
        if (parsed.type === 'ack')  return null; // resolve void
        if (parsed.type === 'nack') return new Error('NACK — device rejected the command');
        return undefined;
      },
      timeoutMs,
      'Timeout — no ACK from device'
    );
  });
}

module.exports = {
  listAllPorts, findE1Ports,
  connect, disconnect, isConnected,
  query, command,
};
</file>

<file path="mac/Sources/ElectraKit/Device.swift">
import Foundation

/// High-level Electra One operations. An actor, so every exchange is
/// serialized — which is exactly the single-in-flight guarantee the transport
/// relies on. Mirrors lib/device.js.
public actor E1Device {
    private let transport: MIDITransport

    public init(transport: MIDITransport = MIDITransport()) {
        self.transport = transport
    }

    @discardableResult
    public func connect() throws -> PortNames {
        try transport.connect()
    }

    public func disconnect() {
        transport.disconnect()
    }

    public var isConnected: Bool { transport.connected }

    // ── Info ──────────────────────────────────────────────────────────────

    public func getInfo() async throws -> DeviceInfo {
        let (_, payload) = try await transport.query(E1Proto.infoRequest())
        return try JSONDecoder().decode(DeviceInfo.self, from: Data(payload))
    }

    // ── Presets ───────────────────────────────────────────────────────────

    /// Raw preset JSON text for a slot (or the active slot when nil).
    /// Throws `.empty` for empty slots.
    public func getPresetRaw(bank: Int?, slot: Int?) async throws -> String {
        let (_, payload) = try await transport.query(E1Proto.presetRequest(bank: bank, slot: slot))
        if payload.isEmpty { throw E1Error.empty }
        guard let text = String(bytes: payload, encoding: .utf8) else {
            throw E1Error.decode("preset is not valid text")
        }
        return text
    }

    /// Pretty-printed preset JSON for a slot (best effort: returns raw text if
    /// it can't be re-serialized).
    public func getPresetPretty(bank: Int?, slot: Int?) async throws -> String {
        let raw = try await getPresetRaw(bank: bank, slot: slot)
        guard let data = raw.data(using: .utf8),
              let obj = try? JSONSerialization.jsonObject(with: data),
              let pretty = try? JSONSerialization.data(withJSONObject: obj, options: [.prettyPrinted, .sortedKeys]),
              let s = String(data: pretty, encoding: .utf8)
        else { return raw }
        return s
    }

    /// Upload preset JSON. When bank/slot are given, arms that slot first
    /// (uploads always target the active slot).
    public func putPreset(json: String, bank: Int?, slot: Int?) async throws {
        if let b = bank, let s = slot {
            try await transport.command(E1Proto.presetSlotSelect(bank: b, slot: s))
        }
        try await transport.command(E1Proto.presetUpload(json: json))
    }

    public func getLua(bank: Int?, slot: Int?) async throws -> String {
        let (_, payload) = try await transport.query(E1Proto.luaRequest(bank: bank, slot: slot))
        return String(bytes: payload, encoding: .utf8) ?? ""
    }

    /// Upload a preset and (optionally) its Lua script to a slot. Arms the slot
    /// first, sends the preset, then the Lua — matching how the web editor
    /// publishes a project.
    public func putProject(json: String, lua: String?, bank: Int?, slot: Int?) async throws {
        if let b = bank, let s = slot {
            try await transport.command(E1Proto.presetSlotSelect(bank: b, slot: s))
        }
        try await transport.command(E1Proto.presetUpload(json: json))
        if let lua, !lua.isEmpty {
            try await transport.command(E1Proto.luaUpload(source: lua))
        }
    }

    public func switchSlot(bank: Int, slot: Int) async throws {
        try await transport.command(E1Proto.presetSlotSelect(bank: bank, slot: slot))
    }

    // ── Scanning ──────────────────────────────────────────────────────────

    /// Scan a single slot. Empty/timeout → `.empty`; malformed → `.error`.
    public func scanSlot(bank: Int, slot: Int, timeout: TimeInterval = 1.5) async -> SlotState {
        do {
            let (_, payload) = try await transport.query(
                E1Proto.presetRequest(bank: bank, slot: slot), timeout: timeout)
            if payload.isEmpty {
                return SlotState(slot: slot, status: .empty)
            }
            let summary = try Self.summarize(payload)
            return SlotState(slot: slot, status: .ok, name: summary.name)
        } catch E1Error.empty, E1Error.timeout {
            return SlotState(slot: slot, status: .empty)
        } catch {
            let msg = (error as? E1Error)?.description ?? "\(error)"
            return SlotState(slot: slot, status: .error, error: msg)
        }
    }

    // ── Parsing ───────────────────────────────────────────────────────────

    public func summarize(bank: Int?, slot: Int?) async throws -> PresetSummary {
        let (_, payload) = try await transport.query(E1Proto.presetRequest(bank: bank, slot: slot))
        if payload.isEmpty { throw E1Error.empty }
        return try Self.summarize(payload)
    }

    static func summarize(_ payload: [UInt8]) throws -> PresetSummary {
        guard let obj = try JSONSerialization.jsonObject(with: Data(payload)) as? [String: Any] else {
            throw E1Error.decode("preset is not a JSON object")
        }
        let devices = obj["devices"] as? [[String: Any]] ?? []
        return PresetSummary(
            name: obj["name"] as? String ?? "(unnamed)",
            version: obj["version"] as? Int,
            projectId: obj["projectId"] as? String,
            pages: (obj["pages"] as? [Any])?.count ?? 0,
            controls: (obj["controls"] as? [Any])?.count ?? 0,
            devices: devices.count,
            deviceNames: devices.compactMap { $0["name"] as? String }
        )
    }

    /// Summarize raw JSON text (used by the UI after an edit/preview).
    public static func summarize(text: String) -> PresetSummary? {
        guard let data = text.data(using: .utf8),
              let s = try? summarize(Array(data)) else { return nil }
        return s
    }
}
</file>

<file path="mac/Sources/ElectraKit/PresetDocument.swift">
import Foundation

/// An editable Electra One preset.
///
/// Backed by the full parsed JSON (`root`) so that **every** field round-trips
/// untouched — editing only mutates the keys we explicitly change. This is the
/// safe-upload guarantee: we never reserialize a lossy model back to the device.
public struct PresetDocument {
    public private(set) var root: [String: Any]

    /// Optional Lua script associated with the preset. Populated when importing
    /// an `.eproj` project (which embeds it) or when fetched from the device.
    /// Not part of `root`, so it never leaks into the preset JSON upload.
    public var lua: String? = nil

    public init?(jsonString: String) {
        guard let data = jsonString.data(using: .utf8),
              let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else { return nil }
        root = obj
    }

    public init(root: [String: Any]) { self.root = root }

    // ── Logical screen ─────────────────────────────────────────────────────

    /// Electra One logical screen size (preset coordinate space).
    public static let screenWidth: Double = 1024
    public static let screenHeight: Double = 575

    /// The six assignable Electra colors (plus white) for the palette picker.
    public static let palette: [String] = [
        "FFFFFF", "F45C51", "F49500", "529DEC", "03A598", "C44795",
    ]

    // ── Top-level ──────────────────────────────────────────────────────────

    public var name: String {
        get { root["name"] as? String ?? "" }
        set { root["name"] = newValue }
    }

    public var version: Int { root["version"] as? Int ?? 2 }
    public var projectId: String? { root["projectId"] as? String }

    public struct Page: Identifiable, Hashable {
        public let id: Int
        public var name: String
    }

    public var pages: [Page] {
        let arr = root["pages"] as? [[String: Any]] ?? []
        let parsed = arr.compactMap { p -> Page? in
            guard let id = p["id"] as? Int else { return nil }
            return Page(id: id, name: p["name"] as? String ?? "Page \(id)")
        }
        return parsed.isEmpty ? [Page(id: 1, name: "Page 1")] : parsed
    }

    public var deviceNames: [String] {
        (root["devices"] as? [[String: Any]] ?? []).compactMap { $0["name"] as? String }
    }

    // ── Controls ─────────────────────────────────────────────────────────────

    public struct Control: Identifiable, Hashable {
        public var id: Int
        public var type: String
        public var variant: String?
        public var name: String
        public var colorHex: String
        public var x: Double, y: Double, w: Double, h: Double
        public var pageId: Int
        public var controlSetId: Int
        public var potId: Int?
        public var messageType: String?
        public var parameterNumber: Int?
        public var deviceId: Int?
        public var minValue: Int?
        public var maxValue: Int?
        public var visible: Bool
    }

    private static func parseControl(_ c: [String: Any]) -> Control? {
        guard let id = c["id"] as? Int else { return nil }
        let bounds = c["bounds"] as? [Double] ?? (c["bounds"] as? [Int])?.map(Double.init) ?? [0, 0, 0, 0]
        let b = bounds.count == 4 ? bounds : [0, 0, 0, 0]
        let inputs = c["inputs"] as? [[String: Any]] ?? []
        let values = c["values"] as? [[String: Any]] ?? []
        let firstMsg = (values.first?["message"]) as? [String: Any]
        return Control(
            id: id,
            type: c["type"] as? String ?? "fader",
            variant: c["variant"] as? String,
            name: c["name"] as? String ?? "",
            colorHex: c["color"] as? String ?? "FFFFFF",
            x: b[0], y: b[1], w: b[2], h: b[3],
            pageId: c["pageId"] as? Int ?? 1,
            controlSetId: c["controlSetId"] as? Int ?? 1,
            potId: inputs.first?["potId"] as? Int,
            messageType: firstMsg?["type"] as? String,
            parameterNumber: firstMsg?["parameterNumber"] as? Int,
            deviceId: firstMsg?["deviceId"] as? Int,
            minValue: firstMsg?["min"] as? Int,
            maxValue: firstMsg?["max"] as? Int,
            visible: c["visible"] as? Bool ?? true
        )
    }

    public func allControls() -> [Control] {
        (root["controls"] as? [[String: Any]] ?? []).compactMap { Self.parseControl($0) }
    }

    public func controls(onPage pageId: Int) -> [Control] {
        allControls().filter { $0.pageId == pageId }
    }

    public func control(id: Int) -> Control? {
        allControls().first { $0.id == id }
    }

    // ── Mutation ─────────────────────────────────────────────────────────────

    /// Low-level: mutate the raw dict of the control with the given id.
    public mutating func mutateControl(id: Int, _ body: (inout [String: Any]) -> Void) {
        guard var controls = root["controls"] as? [[String: Any]] else { return }
        for i in controls.indices where (controls[i]["id"] as? Int) == id {
            var c = controls[i]
            body(&c)
            controls[i] = c
            break
        }
        root["controls"] = controls
    }

    public mutating func setControlName(id: Int, _ name: String) {
        mutateControl(id: id) { $0["name"] = name }
    }

    public mutating func setControlColor(id: Int, hex: String) {
        mutateControl(id: id) { $0["color"] = hex }
    }

    public mutating func setControlBounds(id: Int, x: Double, y: Double, w: Double, h: Double) {
        mutateControl(id: id) { $0["bounds"] = [Int(x.rounded()), Int(y.rounded()), Int(w.rounded()), Int(h.rounded())] }
    }

    public mutating func setMessageParameterNumber(id: Int, _ number: Int) {
        mutateControl(id: id) { c in
            var values = c["values"] as? [[String: Any]] ?? []
            if values.isEmpty { values = [["id": "value", "message": [String: Any]()]] }
            var v = values[0]
            var m = v["message"] as? [String: Any] ?? [:]
            m["parameterNumber"] = number
            v["message"] = m
            values[0] = v
            c["values"] = values
        }
    }

    public mutating func setMessageType(id: Int, _ type: String) {
        mutateControl(id: id) { c in
            var values = c["values"] as? [[String: Any]] ?? []
            if values.isEmpty { values = [["id": "value", "message": [String: Any]()]] }
            var v = values[0]
            var m = v["message"] as? [String: Any] ?? [:]
            m["type"] = type
            v["message"] = m
            values[0] = v
            c["values"] = values
        }
    }

    public mutating func setControlType(id: Int, _ type: String) {
        mutateControl(id: id) { $0["type"] = type }
    }

    public mutating func removeControl(id: Int) {
        guard var controls = root["controls"] as? [[String: Any]] else { return }
        controls.removeAll { ($0["id"] as? Int) == id }
        root["controls"] = controls
    }

    /// Add a fresh fader control on a page, placed in the next free grid cell.
    @discardableResult
    public mutating func addControl(pageId: Int, deviceId: Int? = nil) -> Int {
        var controls = root["controls"] as? [[String: Any]] ?? []
        let newId = (controls.compactMap { $0["id"] as? Int }.max() ?? 0) + 1
        let dev = deviceId ?? (root["devices"] as? [[String: Any]])?.first?["id"] as? Int ?? 1

        // Place into a 6-col × 4-row grid.
        let used = controls.filter { ($0["pageId"] as? Int) == pageId }.count
        let cols = 6, rows = 4
        let idx = used % (cols * rows)
        let col = idx % cols, row = idx / cols
        let cw = Self.screenWidth / Double(cols), rh = Self.screenHeight / Double(rows)
        let bx = Int((Double(col) * cw + 10).rounded())
        let by = Int((Double(row) * rh + 12).rounded())
        let bw = Int((cw - 20).rounded())
        let bh = Int((rh - 24).rounded())
        let potId = (used % 12) + 1

        let control: [String: Any] = [
            "id": newId,
            "type": "fader",
            "variant": "dial",
            "visible": true,
            "name": "CC #\(newId)",
            "color": Self.palette[1 + (newId % (Self.palette.count - 1))],
            "bounds": [bx, by, bw, bh],
            "pageId": pageId,
            "controlSetId": 1,
            "inputs": [["potId": potId, "valueId": "value"]],
            "values": [[
                "message": ["type": "cc7", "min": 0, "max": 127, "parameterNumber": newId, "deviceId": dev],
                "defaultValue": 0,
                "id": "value",
            ]],
        ]
        controls.append(control)
        root["controls"] = controls
        return newId
    }

    public mutating func renamePage(id: Int, to name: String) {
        guard var pages = root["pages"] as? [[String: Any]] else { return }
        for i in pages.indices where (pages[i]["id"] as? Int) == id {
            pages[i]["name"] = name
        }
        root["pages"] = pages
    }

    // ── Serialization ──────────────────────────────────────────────────────

    public func jsonString(pretty: Bool = false) -> String {
        let opts: JSONSerialization.WritingOptions = pretty ? [.prettyPrinted, .sortedKeys] : []
        guard let data = try? JSONSerialization.data(withJSONObject: root, options: opts),
              let s = String(data: data, encoding: .utf8) else { return "{}" }
        return s
    }

    // ── Templates ────────────────────────────────────────────────────────────

    public static func newPreset(name: String = "New Preset") -> PresetDocument {
        let root: [String: Any] = [
            "version": 2,
            "name": name,
            "projectId": Self.makeProjectId(),
            "pages": [
                ["id": 1, "name": "Page 1"],
                ["id": 2, "name": "Page 2"],
            ],
            "devices": [
                ["id": 1, "name": "MIDI Device 1", "port": 1, "channel": 1],
            ],
            "groups": [[String: Any]](),
            "overlays": [[String: Any]](),
            "controls": [[String: Any]](),
        ]
        return PresetDocument(root: root)
    }

    private static func makeProjectId() -> String {
        let chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"
        return String((0..<20).map { _ in chars.randomElement()! })
    }
}
</file>

<file path="mac/Sources/ElectraKit/Protocol.swift">
import Foundation

/// Electra One SysEx framing and message classification.
///
/// Mirrors lib/protocol.js. Manufacturer ID is `00 21 45`. Requests use op
/// `0x02`; data dumps/uploads use op `0x01`. Uploads always go to the *active*
/// slot — to target a slot, arm it first with `presetSlotSelect` (`0x14 0x08`).
public enum E1Proto {
    public static let sox: UInt8 = 0xF0
    public static let eox: UInt8 = 0xF7
    public static let manufacturer: [UInt8] = [0x00, 0x21, 0x45]

    enum Op {
        static let upload: UInt8 = 0x01
        static let request: UInt8 = 0x02
        static let response: UInt8 = 0x01
        static let selectSlot: UInt8 = 0x14
        static let ackNack: UInt8 = 0x7E
    }

    enum Res {
        static let preset: UInt8 = 0x01
        static let lua: UInt8 = 0x0C
        static let info: UInt8 = 0x7F
        static let runtime: UInt8 = 0x7E
    }

    // ACK/NACK codes carried in the byte after the 0x7E op.
    static let ack: UInt8 = 0x01
    static let nak: UInt8 = 0x00

    static func frame(_ bytes: UInt8...) -> [UInt8] {
        [sox] + manufacturer + bytes + [eox]
    }

    public static func infoRequest() -> [UInt8] {
        frame(Op.request, Res.info)
    }

    public static func presetRequest(bank: Int?, slot: Int?) -> [UInt8] {
        if let b = bank, let s = slot {
            return frame(Op.request, Res.preset, UInt8(b), UInt8(s))
        }
        return frame(Op.request, Res.preset)
    }

    public static func luaRequest(bank: Int?, slot: Int?) -> [UInt8] {
        if let b = bank, let s = slot {
            return frame(Op.request, Res.lua, UInt8(b), UInt8(s))
        }
        return frame(Op.request, Res.lua)
    }

    /// Build a preset-upload message. The JSON body follows the resource byte
    /// directly — there is no bank/slot variant of the upload command.
    public static func presetUpload(json: String) -> [UInt8] {
        let body = Array(json.utf8)
        return [sox] + manufacturer + [Op.upload, Res.preset] + body + [eox]
    }

    /// "Set preset slot" — arm the given bank/slot as the active target.
    public static func presetSlotSelect(bank: Int, slot: Int) -> [UInt8] {
        frame(Op.selectSlot, 0x08, UInt8(bank), UInt8(slot))
    }

    /// Upload a Lua script to the active slot (op `0x01`, resource `0x0C`).
    public static func luaUpload(source: String) -> [UInt8] {
        let body = Array(source.utf8)
        return [sox] + manufacturer + [Op.upload, Res.lua] + body + [eox]
    }

    /// A classified inbound SysEx message.
    public enum Message {
        case data(resource: UInt8, payload: [UInt8])
        case ack
        case nack
        case status(code: UInt8)   // e.g. 0x05 notification — not a result
        case unknown
    }

    public static func classify(_ msg: [UInt8]) -> Message {
        guard msg.count >= 6,
              msg[0] == sox,
              msg[1] == 0x00, msg[2] == 0x21, msg[3] == 0x45,
              msg.last == eox
        else { return .unknown }

        let op = msg[4]
        if op == Op.response {
            let payload = Array(msg[6..<(msg.count - 1)])
            return .data(resource: msg[5], payload: payload)
        }
        if op == Op.ackNack {
            switch msg[5] {
            case ack: return .ack
            case nak: return .nack
            default:  return .status(code: msg[5])
            }
        }
        return .unknown
    }
}
</file>

<file path="mac/Sources/ElectraOneApp/App.swift">
import SwiftUI
import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
    }
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { true }
}

@main
struct ElectraOneApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var delegate
    @StateObject private var model = AppModel()

    var body: some Scene {
        WindowGroup("Electra One") {
            ContentView()
                .environmentObject(model)
                .frame(minWidth: 760, minHeight: 500)
                .onAppear { model.start() }
        }
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("New Preset") { model.newDocument() }
                    .keyboardShortcut("n", modifiers: .command)
                Button("Open…") { model.openFile() }
                    .keyboardShortcut("o", modifiers: .command)
            }
            CommandGroup(replacing: .saveItem) {
                Button("Save") { model.saveToFile() }
                    .keyboardShortcut("s", modifiers: .command)
                    .disabled(model.document == nil)
                Button("Save As…") { model.saveToFileAs() }
                    .keyboardShortcut("s", modifiers: [.command, .shift])
                    .disabled(model.document == nil)
                Button("Save to Device…") { model.presentSaveToDevice() }
                    .keyboardShortcut("d", modifiers: .command)
                    .disabled(model.document == nil || !model.isConnected)
            }
            CommandGroup(after: .toolbar) {
                Button("Rescan Bank") { model.rescan() }
                    .keyboardShortcut("r", modifiers: .command)
                    .disabled(!model.isConnected)
                Button("Add Control") { model.addControl() }
                    .keyboardShortcut("k", modifiers: .command)
                    .disabled(model.document == nil)
            }
        }
    }
}
</file>

<file path=".gitignore">
# Compiled Lua sources
luac.out

# luarocks build files
*.src.rock
*.zip
*.tar.gz

# Object files
*.o
*.os
*.ko
*.obj
*.elf

# Precompiled Headers
*.gch
*.pch

# Libraries
*.lib
*.a
*.la
*.lo
*.def
*.exp

# Shared objects (inc. Windows DLLs)
*.dll
*.so
*.so.*
*.dylib

# Executables
*.exe
*.out
*.app
*.i*86
*.x86_64
*.hex

node_modules/
.DS_Store

# Swift / macOS app
mac/.build/
mac/ElectraOne.app/
*.swiftpm
</file>

<file path="README.md">
# e1 — Electra One companion app

A TUI + CLI for managing your **Electra One** (mk2 / mini) over USB MIDI —
no web app required. Auto-connects to the device's CTRL port and lets you
browse, download, view, edit, upload, and activate presets.

## Requirements

- Node.js ≥ 18
- An Electra One connected over USB (shows up as `Electra Controller … CTRL`)

## Install

```bash
npm install
```

## Launch the app (TUI)

```bash
npm start          # or: node bin/e1.js   (tui is the default command)
```

The app auto-connects, shows your device (model / firmware / serial), and
scans bank 0. Keys:

| Key | Action |
|-----|--------|
| `↑`/`↓` (or `j`/`k`) | Move between slots |
| `Enter` | View the selected preset (name, pages, controls, devices) |
| `p` | **Pull** — download the selected preset to `<name>.json` |
| `e` | **Edit** — pull → open in `$EDITOR` → upload back on save |
| `u` | **Upload** — push a `.json` file from disk to the selected slot |
| `s` | **Activate** — make the selected slot active on the device |
| `[` / `]` | Previous / next bank |
| `r` | Re-scan the current bank |
| `q` | Quit |

> Editing uses `$VISUAL`/`$EDITOR` (falls back to `vi`). Save & close the
> editor to upload; if the JSON is unchanged or invalid, nothing is sent.

## CLI

Every operation is also scriptable:

```bash
node bin/e1.js ports                 # list MIDI ports, identify the Electra
node bin/e1.js info                  # model, firmware, serial
node bin/e1.js scan -b 0 -n 12       # what's loaded in a bank
node bin/e1.js pull -b 0 -s 1 -o my.json
node bin/e1.js push my.json -b 0 -s 1
node bin/e1.js pull-lua -b 0 -s 1 -o main.lua
node bin/e1.js backup -b 0 -o ./backup
node bin/e1.js switch -b 0 -s 1
```

## How it works

- **`lib/transport.js`** — MIDI I/O. Opens the CTRL port **once** and keeps a
  persistent connection, serializing SysEx exchanges through a queue and
  reassembling fragmented responses. (Opening/closing per request crashes
  libuv on macOS.)
- **`lib/protocol.js`** — Electra One SysEx framing (manufacturer `00 21 45`).
  Requests use op `0x02`; uploads use op `0x01` and always target the
  **active** slot, so `putPreset` first arms the slot with the "set preset
  slot" command (`0x14 0x08 bank slot`). ACK/NACK are decoded from `7E`
  messages (`01` = ack, `00` = nack; other codes are notifications).
- **`lib/device.js`** — high-level operations (info, get/put preset, scan,
  backup, switch) returning clean structured data.
- **`tui/app.mjs`** — the Ink front-end (rendered via `htm`, no build step).

---

# Appendix: Lua learning kit

The `scripts/` directory also contains a progressive set of 5 Lua scripts for
learning the Electra One's scripting capabilities. To use them: open a preset
at [app.electra.one](https://app.electra.one), click the **Lua** tab, paste a
script, **Upload**, and watch the **Console** for `print()` output.

| # | Script | Concepts | Difficulty |
|---|--------|----------|------------|
| 1 | `01_hello_world.lua` | print, callbacks, timer, controller info | ⭐ |
| 2 | `02_midi_io.lua` | Send/receive MIDI, transport sync | ⭐⭐ |
| 3 | `03_control_manipulation.lua` | Dynamic UI, pages, formatters | ⭐⭐⭐ |
| 4 | `04_midi_lfo.lua` | Timer-driven LFO, graphics API | ⭐⭐⭐⭐ |
| 5 | `05_sysex_patch_handler.lua` | SysEx parsing, patch dumps, persistence | ⭐⭐⭐⭐⭐ |

---

## Script 1: Hello World & Basics

**What you'll learn:**
- The `print()` function for debugging
- Preset lifecycle: `onLoad` → `onReady` → `onEnter`
- Querying controller model and firmware
- Basic timer usage

**Key APIs:**
```lua
print("message")                    -- Log to console
controller.getModel()               -- "mk2" or "mini"
controller.getFirmwareVersion()     -- e.g., "4.0.5"
info.setText("status message")      -- Display in status bar
timer.setPeriod(500)                -- Set timer interval (ms)
timer.enable() / timer.disable()
```

---

## Script 2: MIDI Input/Output

**What you'll learn:**
- Sending all MIDI message types
- Receiving MIDI with callbacks
- External clock sync with transport module
- Port routing (PORT_1, PORT_2)

**Key APIs:**
```lua
-- Sending
midi.sendControlChange(PORT_1, channel, cc, value)
midi.sendNoteOn(PORT_1, channel, note, velocity)
midi.sendProgramChange(PORT_1, channel, program)
midi.sendNrpn(PORT_1, channel, param, value, lsbFirst, reset)
midi.sendSysex(PORT_1, {bytes...})

-- Receiving (define these functions)
function midi.onControlChange(midiInput, channel, cc, value)
function midi.onNoteOn(midiInput, channel, note, velocity)
function midi.onSysex(midiInput, sysexBlock)

-- Transport sync
transport.enable()
function transport.onClock(midiInput)   -- 24 per quarter note
function transport.onStart(midiInput)
function transport.onStop(midiInput)
```

**Ableton Live Tips:**
- Enable Electra One as MIDI input in Live's preferences
- Turn on "Remote" for the Electra port
- Use MIDI Map mode to assign CCs
- Send MIDI clock from Live for transport sync

---

## Script 3: Control Manipulation

**What you'll learn:**
- Getting/modifying control properties
- Dynamic show/hide based on context
- Moving controls between slots
- Value formatters for custom display
- Page and group management

**Key APIs:**
```lua
-- Controls
local ctrl = controls.get(refId)
ctrl:setVisible(true/false)
ctrl:setSlot(slot)              -- Move to grid position
ctrl:setName("New Name")
ctrl:setColor(0xFF0000)         -- RGB hex
ctrl:getValue("value")          -- Get Value object

-- Values & Formatting
function formatPercent(valueObject, value)
    return string.format("%d%%", value)
end

-- Value callbacks
function onFaderChange(valueObject, value)
    local ctrl = valueObject:getControl()
    -- Do something with the value
end

-- Pages
pages.display(pageId)
pages.getActive()

-- Overlays (list items)
overlays.create(id, {
    {value = 0, label = "Option 1"},
    {value = 1, label = "Option 2"},
})
```

---

## Script 4: MIDI LFO Generator

**What you'll learn:**
- Timer-driven periodic execution
- Waveform generation (sine, triangle, saw, square)
- `parameterMap` for value manipulation
- Graphics API for custom visualizations
- State management patterns

**Key APIs:**
```lua
-- Timer
timer.setPeriod(20)     -- 50Hz update
timer.enable()
function timer.onTick()
    -- Called every period
end

-- Parameter Map
parameterMap.set(deviceId, PT_CC7, paramNum, value)
parameterMap.get(deviceId, PT_CC7, paramNum)
parameterMap.modulate(deviceId, type, param, modValue, depth)

-- Graphics (for Custom controls)
graphics.setColor(0x00FFFF)
graphics.drawLine(x1, y1, x2, y2)
graphics.fillRect(x, y, w, h)
graphics.drawCircle(x, y, radius)
graphics.print(x, y, "text", width, CENTER)
```

---

## Script 5: SysEx Patch Handler

**What you'll learn:**
- Patch request/response callbacks
- SysEx message parsing with `sysexBlock`
- Building and sending custom SysEx
- Checksum calculation
- Data persistence with `persist()`/`recall()`
- User functions in Preset Menu

**Key APIs:**
```lua
-- Patch callbacks (define in preset JSON first)
function patch.onRequest(device)
    -- Send your patch request here
end

function patch.onResponse(device, responseId, sysexBlock)
    -- Parse incoming patch dump
    local length = sysexBlock:getLength()
    local byte = sysexBlock:peek(position)
end

-- Persistence
persist(luaTable)       -- Save to non-volatile storage
recall(luaTable)        -- Load from storage

-- User functions in preset menu
preset.userFunctions = {
    pot1 = { call = myFunction, name = "Button", close = true },
}
```

---

## Parameter Types Reference

| Constant | Type | Usage |
|----------|------|-------|
| `PT_CC7` | CC (7-bit) | Standard MIDI CC 0-127 |
| `PT_CC14` | CC (14-bit) | High-res CC pairs |
| `PT_NRPN` | NRPN | Non-Registered Parameter |
| `PT_RPN` | RPN | Registered Parameter |
| `PT_SYSEX` | SysEx | System Exclusive params |
| `PT_NOTE` | Note | Note messages |
| `PT_PROGRAM` | Program | Program change |
| `PT_VIRTUAL` | Virtual | Lua-only, no MIDI |

## Global Constants

```lua
-- Ports
PORT_1, PORT_2, PORT_CTRL

-- Interfaces
USB_DEV, USB_HOST, MIDI_IO

-- Controller Models
MODEL_MK2, MODEL_MINI

-- Origins (in parameterMap.onChange)
ORIGIN_LUA, ORIGIN_CONTROL, ORIGIN_MIDI

-- Control Sets
CONTROL_SET_1, CONTROL_SET_2, CONTROL_SET_3

-- Pot IDs
POT_1 through POT_12

-- Bounds array indices
X, Y, WIDTH, HEIGHT

-- Text alignment
LEFT, CENTER, RIGHT

-- Curve segments
TOP_LEFT, TOP_RIGHT, BOTTOM_LEFT, BOTTOM_RIGHT
```

---

## Debugging Tips

1. **Use `print()` liberally** - Check the Console in the web editor
2. **Start simple** - Test callbacks one at a time
3. **Check ref IDs** - Control references must match the preset
4. **Verify MIDI routing** - Use the MIDI Console to monitor traffic
5. **Firmware version** - Some features require v4.0+

## Resources

- [Official Lua Extension Docs](https://docs.electra.one/developers/luaext.html)
- [Lua Crash Course](https://docs.electra.one/luacourse)
- [Preset Editor](https://app.electra.one)
- [Electra One Forum](https://forum.electra.one)
- [Preset Library](https://app.electra.one/presets)

## Hardware Notes (Electra One Mini)

- 6 touch-sensitive knobs (vs 12 on mkII)
- No touchscreen (knob-first interaction)
- Same Lua capabilities as mkII
- Presets are cross-compatible with mkII
- Use Performance overlays for more parameters

---

Happy scripting! 🎹
</file>

<file path="lib/device.js">
'use strict';

/**
 * device.js
 *
 * High-level Electra One operations.
 * This is the public API — import this in commands or tests.
 *
 * Each function validates inputs, composes protocol messages,
 * sends via transport, and returns clean structured data.
 */

const path = require('path');
const fs   = require('fs');

const proto     = require('./protocol');
const transport = require('./transport');

// ── Utilities ─────────────────────────────────────────────────────────────────

/**
 * Validate and parse bank/slot arguments.
 * Returns { bank, slot } as integers, or { bank: undefined, slot: undefined }
 * for "active slot" requests.
 */
function parseSlot(bank, slot) {
  if (bank == null && slot == null) return { bank: undefined, slot: undefined };

  if (bank == null || slot == null) {
    throw new Error('--bank and --slot must be used together');
  }
  const b = parseInt(bank, 10);
  const s = parseInt(slot, 10);
  if (isNaN(b) || b < 0 || b > 11) throw new Error('--bank must be 0–11');
  if (isNaN(s) || s < 0 || s > 11) throw new Error('--slot must be 0–11');
  return { bank: b, slot: s };
}

/**
 * Produce a filesystem-safe filename from a preset name.
 * @param {string} name
 * @returns {string}
 */
function safeName(name) {
  return (name || 'preset')
    .trim()
    .replace(/[^a-z0-9_\-. ]/gi, '_')
    .replace(/\s+/g, '_')
    .slice(0, 60);
}

/**
 * Thrown when a slot is empty. The device answers a preset request for an
 * empty slot with a zero-length data payload (rather than timing out), so we
 * surface that as a distinct, catchable condition.
 */
class EmptySlotError extends Error {
  constructor(message = 'Slot is empty') {
    super(message);
    this.name = 'EmptySlotError';
    this.empty = true;
  }
}

/** @param {Error} e @returns {boolean} true if e means "nothing in this slot" */
function isEmptySlot(e) {
  return !!(e && (e.empty ||
    e.message.includes('Timeout') ||
    e.message.includes('did not respond')));
}

// ── Device operations ─────────────────────────────────────────────────────────

/**
 * @typedef {object} DeviceInfo
 * @property {string} versionText
 * @property {number} versionSeq
 * @property {string} serial
 * @property {string} hwRevision
 * @property {string} model
 * @property {number} modelNum
 */

/**
 * Fetch hardware and firmware info from the device.
 * @returns {Promise<DeviceInfo>}
 */
async function getInfo() {
  const { payload } = await transport.query(proto.infoRequest());
  return proto.decodeJSON(payload);
}

/**
 * @typedef {object} Preset
 * @property {string} name
 * @property {number} version
 * @property {string} [projectId]
 * @property {object[]} pages
 * @property {object[]} devices
 * @property {object[]} controls
 */

/**
 * Download a preset from the device.
 * @param {object} [opts]
 * @param {number} [opts.bank]
 * @param {number} [opts.slot]
 * @returns {Promise<Preset>}
 */
async function getPreset({ bank, slot } = {}) {
  const s = parseSlot(bank, slot);
  const { payload } = await transport.query(proto.presetRequest(s.bank, s.slot));
  if (!payload || payload.length === 0) throw new EmptySlotError();
  return proto.decodeJSON(payload);
}

/**
 * Upload a preset to the device.
 * @param {Preset|object} preset  - already-parsed preset object
 * @param {object} [opts]
 * @param {number} [opts.bank]    - omit to replace the active slot
 * @param {number} [opts.slot]
 * @returns {Promise<void>}
 */
async function putPreset(preset, { bank, slot } = {}) {
  if (!preset || typeof preset !== 'object') throw new Error('preset must be an object');
  const s = parseSlot(bank, slot);
  // Uploads always go to the active slot, so arm the target slot first.
  if (s.bank != null && s.slot != null) {
    await transport.command(proto.presetSlotSelect(s.bank, s.slot));
  }
  const jsonStr = JSON.stringify(preset);
  await transport.command(proto.presetUpload(jsonStr));
}

/**
 * Download the Lua script from a preset slot.
 * @param {object} [opts]
 * @param {number} [opts.bank]
 * @param {number} [opts.slot]
 * @returns {Promise<string>} Lua source code
 */
async function getLua({ bank, slot } = {}) {
  const s = parseSlot(bank, slot);
  const { payload } = await transport.query(proto.luaRequest(s.bank, s.slot));
  return proto.decodeText(payload);
}

/**
 * Upload a Lua script to a preset slot.
 * @param {string} luaStr  - Lua source code
 * @param {object} [opts]
 * @param {number} [opts.bank]    - omit to target the active slot
 * @param {number} [opts.slot]
 * @returns {Promise<void>}
 */
async function putLua(luaStr, { bank, slot } = {}) {
  if (typeof luaStr !== 'string') throw new Error('luaStr must be a string');
  const s = parseSlot(bank, slot);
  await transport.command(proto.luaUpload(luaStr, s.bank, s.slot));
}

/**
 * Convenience: load a Lua file and push it to the device.
 *
 * @param {string} filePath
 * @param {object} [opts]
 * @param {number} [opts.bank]
 * @param {number} [opts.slot]
 * @returns {Promise<string>} the Lua source that was pushed
 */
async function pushLuaFromFile(filePath, { bank, slot } = {}) {
  let lua;
  try {
    lua = fs.readFileSync(filePath, 'utf8');
  } catch {
    throw new Error(`Cannot read file: ${filePath}`);
  }

  if (!lua.trim()) {
    throw new Error(`Lua file is empty: ${path.basename(filePath)}`);
  }

  await putLua(lua, { bank, slot });
  return lua;
}

/**
 * @typedef {object} SlotResult
 * @property {number} bank
 * @property {number} slot
 * @property {'ok'|'empty'|'error'} status
 * @property {string} [name]
 * @property {string} [error]
 */

/**
 * Scan a range of slots and return what's in them.
 * Empty slots typically time out — that's treated as 'empty', not an error.
 *
 * @param {object} [opts]
 * @param {number} [opts.bank=0]       - which bank to scan
 * @param {number} [opts.slotCount=12] - how many slots to check
 * @param {number} [opts.timeoutMs=3000] - per-slot timeout (shorter than default)
 * @param {(result: SlotResult) => void} [opts.onSlot] - progress callback
 * @returns {Promise<SlotResult[]>}
 */
async function scanSlots({ bank = 0, slotCount = 12, timeoutMs = 3000, onSlot } = {}) {
  const results = [];

  for (let slot = 0; slot < slotCount; slot++) {
    let result;
    try {
      const { payload } = await transport.query(
        proto.presetRequest(bank, slot),
        { timeoutMs }
      );
      if (!payload || payload.length === 0) throw new EmptySlotError();
      const preset = proto.decodeJSON(payload);
      result = { bank, slot, status: 'ok', name: preset.name || '(unnamed)' };
    } catch (err) {
      const empty = isEmptySlot(err);
      result = {
        bank, slot,
        status: empty ? 'empty' : 'error',
        error:  empty ? undefined : err.message,
      };
    }

    results.push(result);
    if (onSlot) onSlot(result);
  }

  return results;
}

/**
 * Convenience: pull a preset and save it to a file.
 * Returns the resolved output path.
 *
 * @param {object} [opts]
 * @param {number} [opts.bank]
 * @param {number} [opts.slot]
 * @param {string} [opts.outFile] - defaults to <preset-name>.json
 * @returns {Promise<{ preset: Preset, outFile: string }>}
 */
async function pullPresetToFile({ bank, slot, outFile } = {}) {
  const preset = await getPreset({ bank, slot });
  const dest = outFile || `${safeName(preset.name)}.json`;
  fs.writeFileSync(dest, JSON.stringify(preset, null, 2), 'utf8');
  return { preset, outFile: path.resolve(dest) };
}

/**
 * Convenience: load a preset JSON file and push it to the device.
 *
 * @param {string} filePath
 * @param {object} [opts]
 * @param {number} [opts.bank]
 * @param {number} [opts.slot]
 * @returns {Promise<Preset>} the preset that was pushed
 */
async function pushPresetFromFile(filePath, { bank, slot } = {}) {
  let raw;
  try {
    raw = fs.readFileSync(filePath, 'utf8');
  } catch {
    throw new Error(`Cannot read file: ${filePath}`);
  }

  let preset;
  try {
    preset = JSON.parse(raw);
  } catch (e) {
    throw new Error(`Invalid JSON in ${path.basename(filePath)}: ${e.message}`);
  }

  if (!preset.name || !Array.isArray(preset.controls)) {
    throw new Error('File does not look like an Electra One preset (missing name or controls)');
  }

  await putPreset(preset, { bank, slot });
  return preset;
}


/**
 * Back up all occupied slots in a bank to a directory.
 *
 * @param {object} [opts]
 * @param {number} [opts.bank=0]
 * @param {number} [opts.slotCount=12]
 * @param {string} [opts.outDir='backup']
 * @param {(status: object) => void} [opts.onSlot]
 * @returns {Promise<{ saved: number, skipped: number, outDir: string }>}
 */
async function backupBank({ bank = 0, slotCount = 12, outDir = 'backup', onSlot } = {}) {
  if (!fs.existsSync(outDir)) fs.mkdirSync(outDir, { recursive: true });
  let saved = 0, skipped = 0;
  for (let slot = 0; slot < slotCount; slot++) {
    let status;
    try {
      const preset = await getPreset({ bank, slot });
      const filename = `b${bank}_s${String(slot).padStart(2,'0')}_${safeName(preset.name)}.json`;
      const dest = path.join(outDir, filename);
      fs.writeFileSync(dest, JSON.stringify(preset, null, 2), 'utf8');
      saved++;
      status = { bank, slot, result: 'saved', name: preset.name, file: dest };
    } catch (e) {
      skipped++;
      const empty = isEmptySlot(e);
      status = { bank, slot, result: empty ? 'empty' : 'error', error: empty ? undefined : e.message };
    }
    if (onSlot) onSlot(status);
  }
  return { saved, skipped, outDir: path.resolve(outDir) };
}

/**
 * Switch the active preset slot on the device.
 * @param {number} bank
 * @param {number} slot
 * @returns {Promise<void>}
 */
async function switchSlot(bank, slot) {
  const s = parseSlot(bank, slot);
  await transport.command(proto.presetSlotSelect(s.bank, s.slot));
}

module.exports = {
  getInfo,
  getPreset, putPreset,
  getLua, putLua,
  pushLuaFromFile,
  scanSlots,
  pullPresetToFile, pushPresetFromFile,
  backupBank,
  switchSlot,
  EmptySlotError, isEmptySlot,
};
</file>

<file path="bin/e1.js">
#!/usr/bin/env node
'use strict';

/**
 * bin/e1.js
 *
 * CLI entry point. Commander wiring only — no business logic here.
 * All real work lives in lib/device.js.
 */

const { program } = require('commander');
const transport   = require('../lib/transport');
const device      = require('../lib/device');
const { version } = require('../package.json');

// ── Output helpers ────────────────────────────────────────────────────────────

const log  = (...a) => console.log(...a);
const err  = (...a) => console.error(...a);
const line = (n = 42) => '─'.repeat(n);

/**
 * Wrap an async command handler so errors print cleanly and the process
 * always exits. The persistent MIDI ports keep the event loop alive, so we
 * disconnect and exit explicitly once the command finishes.
 */
const run = (fn) => (...args) =>
  fn(...args)
    .then(() => {
      transport.disconnect();
      process.exit(0);
    })
    .catch((e) => {
      err(`\nError: ${e.message}\n`);
      transport.disconnect();
      process.exit(1);
    });

// ── Command implementations ───────────────────────────────────────────────────

async function cmdPorts() {
  const { inputs, outputs } = transport.listAllPorts();
  const { inputPort, outputPort, inputName, outputName } = transport.findE1Ports();

  log('\nMIDI Input Ports:');
  inputs.forEach((name, i) => {
    const marker = i === inputPort ? ' ◀ Electra One' : '';
    log(`  [${i}] ${name}${marker}`);
  });

  log('\nMIDI Output Ports:');
  outputs.forEach((name, i) => {
    const marker = i === outputPort ? ' ◀ Electra One' : '';
    log(`  [${i}] ${name}${marker}`);
  });

  if (inputPort >= 0) {
    log(`\n✓ Device found → IN: ${inputName} | OUT: ${outputName}\n`);
  } else {
    log('\n✗ No Electra One detected. Check USB connection and try again.\n');
  }
}

async function cmdInfo() {
  process.stdout.write('Querying device… ');
  const info = await device.getInfo();
  log('ok\n');
  log(line());
  log(` Model    : ${info.model.toUpperCase()} (hw rev ${info.hwRevision})`);
  log(` Firmware : ${info.versionText}`);
  log(` Serial   : ${info.serial}`);
  log(line() + '\n');
}

async function cmdPull(opts) {
  const bank = opts.bank != null ? parseInt(opts.bank, 10) : undefined;
  const slot = opts.slot != null ? parseInt(opts.slot, 10) : undefined;

  const where = bank != null ? `bank ${bank}, slot ${slot}` : 'active preset';
  process.stdout.write(`Pulling ${where}… `);

  const { preset, outFile } = await device.pullPresetToFile({
    bank, slot, outFile: opts.out,
  });

  log('ok\n');
  log(`  Name : ${preset.name}`);
  log(`  Pages: ${preset.pages?.length ?? '?'} | Controls: ${preset.controls?.length ?? '?'}`);
  log(`  Saved: ${outFile}\n`);
}

async function cmdPush(file, opts) {
  const bank = opts.bank != null ? parseInt(opts.bank, 10) : undefined;
  const slot = opts.slot != null ? parseInt(opts.slot, 10) : undefined;

  // Detect file type by extension
  if (file.endsWith('.lua')) {
    return cmdPushLua(file, opts);
  }

  const where = bank != null ? `bank ${bank}, slot ${slot}` : 'active slot';
  process.stdout.write(`Validating ${file}… `);

  // pushPresetFromFile validates JSON + structure before sending
  const preset = await device.pushPresetFromFile(file, { bank, slot });
  log('ok\n');
  log(`  Pushed : "${preset.name}" → ${where}`);
  log(`  Controls: ${preset.controls?.length ?? '?'}\n`);
}

async function cmdPushLua(file, opts) {
  const bank = opts.bank != null ? parseInt(opts.bank, 10) : undefined;
  const slot = opts.slot != null ? parseInt(opts.slot, 10) : undefined;

  const where = bank != null ? `bank ${bank}, slot ${slot}` : 'active slot';
  process.stdout.write(`Uploading Lua to ${where}… `);

  const lua = await device.pushLuaFromFile(file, { bank, slot });
  log('ok\n');
  log(`  Pushed : ${require('path').basename(file)} → ${where}`);
  log(`  Lines  : ${lua.split('\n').length}\n`);
}

async function cmdPullLua(opts) {
  const bank = opts.bank != null ? parseInt(opts.bank, 10) : undefined;
  const slot = opts.slot != null ? parseInt(opts.slot, 10) : undefined;

  const where = bank != null ? `bank ${bank}, slot ${slot}` : 'active preset';
  process.stdout.write(`Pulling Lua from ${where}… `);

  const lua     = await device.getLua({ bank, slot });
  const outFile = opts.out || 'main.lua';

  const { writeFileSync } = require('fs');
  const { resolve } = require('path');
  writeFileSync(outFile, lua, 'utf8');

  log('ok\n');
  log(`  Saved: ${resolve(outFile)}`);
  log(`  Lines: ${lua.split('\n').length}\n`);
}

async function cmdScan(opts) {
  const bank      = opts.bank != null ? parseInt(opts.bank, 10) : 0;
  const slotCount = opts.slots != null ? parseInt(opts.slots, 10) : 12;

  log(`\nScanning bank ${bank} (${slotCount} slots)…\n`);
  log(`  Slot  Status    Name`);
  log(`  ────  ────────  ──────────────────────────────────`);

  const results = await device.scanSlots({
    bank,
    slotCount,
    timeoutMs: opts.timeout ? parseInt(opts.timeout, 10) : 3000,
    onSlot: (r) => {
      const status = r.status === 'ok'    ? 'ok      '
                   : r.status === 'empty' ? 'empty   '
                   :                        'error   ';
      const name   = r.status === 'ok'    ? r.name
                   : r.status === 'error' ? `(${r.error})`
                   :                        '—';
      log(`  [${String(r.slot).padStart(2, '0')}]  ${status}  ${name}`);
    },
  });

  const found = results.filter(r => r.status === 'ok');
  log(`\n  ${found.length} of ${slotCount} slots occupied in bank ${bank}.\n`);
}

// ── CLI definition ────────────────────────────────────────────────────────────

program
  .name('e1')
  .description('Manage your Electra One without the web app')
  .version(version);

program
  .command('ports')
  .description('List all MIDI ports and identify the Electra One')
  .action(run(cmdPorts));

program
  .command('info')
  .description('Show device firmware version, model, and serial number')
  .action(run(cmdInfo));

program
  .command('scan')
  .description('Scan preset slots and show what\'s loaded')
  .option('-b, --bank <n>', 'Bank to scan (default: 0)')
  .option('-n, --slots <n>', 'Number of slots to scan (default: 12)')
  .option('-t, --timeout <ms>', 'Per-slot timeout in ms (default: 3000)')
  .action(run(cmdScan));

program
  .command('pull')
  .description('Download a preset from the device to a JSON file')
  .option('-b, --bank <n>', 'Bank number (use with --slot)')
  .option('-s, --slot <n>', 'Slot number (use with --bank)')
  .option('-o, --out <file>', 'Output filename (default: <preset-name>.json)')
  .action(run(cmdPull));

program
  .command('push <file>')
  .description('Upload a preset (.json) or Lua script (.lua) to the device')
  .option('-b, --bank <n>', 'Target bank (use with --slot; default: active slot)')
  .option('-s, --slot <n>', 'Target slot (use with --bank)')
  .action(run(cmdPush));

program
  .command('push-lua <file>')
  .description('Upload a Lua script to a preset slot on the device')
  .option('-b, --bank <n>', 'Target bank (use with --slot; default: active slot)')
  .option('-s, --slot <n>', 'Target slot (use with --bank)')
  .action(run(cmdPushLua));

program
  .command('pull-lua')
  .description('Download the Lua script from the active (or specified) preset slot')
  .option('-b, --bank <n>', 'Bank number')
  .option('-s, --slot <n>', 'Slot number')
  .option('-o, --out <file>', 'Output filename (default: main.lua)')
  .action(run(cmdPullLua));


// ── backup ────────────────────────────────────────────────────────────────────
async function cmdBackup(opts) {
  const bank      = opts.bank   != null ? parseInt(opts.bank, 10)   : 0;
  const slotCount = opts.slots  != null ? parseInt(opts.slots, 10)  : 12;
  const outDir    = opts.out    || 'backup';

  log(`\nBacking up bank ${bank} (${slotCount} slots) → ${outDir}/\n`);
  log('  Slot  Result    Name / File');
  log('  ────  ────────  ' + '─'.repeat(40));

  const { saved, skipped } = await device.backupBank({
    bank, slotCount, outDir,
    onSlot: (s) => {
      if (s.result === 'saved') {
        log(`  [${String(s.slot).padStart(2,'0')}]  saved     ${s.name}  →  ${require('path').basename(s.file)}`);
      } else if (s.result === 'empty') {
        log(`  [${String(s.slot).padStart(2,'0')}]  empty     —`);
      } else {
        log(`  [${String(s.slot).padStart(2,'0')}]  error     (${s.error})`);
      }
    },
  });

  log(`\n  ✓ ${saved} preset(s) saved, ${skipped} slot(s) skipped.\n`);
}

// ── switch ────────────────────────────────────────────────────────────────────
async function cmdSwitch(opts) {
  if (opts.bank == null || opts.slot == null) {
    err('\nError: --bank and --slot are required for switch\n');
    process.exit(1);
  }
  const bank = parseInt(opts.bank, 10);
  const slot = parseInt(opts.slot, 10);
  process.stdout.write(`Switching to bank ${bank}, slot ${slot}… `);
  await device.switchSlot(bank, slot);
  log('ok\n');
}

program
  .command('backup')
  .description('Download all occupied preset slots in a bank to a directory')
  .option('-b, --bank <n>',  'Bank to back up (default: 0)')
  .option('-n, --slots <n>', 'Number of slots to check (default: 12)')
  .option('-o, --out <dir>', 'Output directory (default: ./backup)')
  .action(run(cmdBackup));

program
  .command('switch')
  .description('Switch the active preset slot on the device')
  .requiredOption('-b, --bank <n>', 'Bank number')
  .requiredOption('-s, --slot <n>', 'Slot number')
  .action(run(cmdSwitch));

program
  .command('tui', { isDefault: true })
  .description('Launch the full-screen interactive app (default)')
  .action(() => {
    // The TUI is an ESM module (Ink); load it dynamically from CommonJS.
    import('../tui/app.mjs')
      .then((m) => m.start())
      .then(() => process.exit(0))
      .catch((e) => {
        err(`\nError: ${e.message}\n`);
        transport.disconnect();
        process.exit(1);
      });
  });

program.parse(process.argv);
</file>

<file path="mac/Sources/e1probe/main.swift">
import ElectraKit
import Foundation

@main
struct Probe {
    static func main() async {
        if CommandLine.arguments.contains("doc") { docSelfTest(); return }
        await probeDevice()
    }

    /// Offline model check — no device needed.
    static func docSelfTest() {
        // Round-trip the bundled demo preset, if present.
        let path = "../presets/b0_s00_Demo_Preset.json"
        if let text = try? String(contentsOfFile: path, encoding: .utf8),
           let doc = PresetDocument(jsonString: text) {
            print("Loaded \"\(doc.name)\"  pages: \(doc.pages.count)  controls: \(doc.allControls().count)")

            // Round-trip must preserve every top-level key.
            func topKeys(_ s: String) -> Set<String> {
                guard let o = (try? JSONSerialization.jsonObject(with: Data(s.utf8))) as? [String: Any] else { return [] }
                return Set(o.keys)
            }
            let before = topKeys(text), after = topKeys(doc.jsonString())
            print("Top-level keys preserved: \(before == after)  (\(before.sorted().joined(separator: ",")))")

            // Mutate one control; confirm only that control's name changed and counts hold.
            var edited = doc
            if let first = doc.allControls().first {
                edited.setControlName(id: first.id, "RENAMED")
                let ok = edited.control(id: first.id)?.name == "RENAMED"
                    && edited.allControls().count == doc.allControls().count
                print("Targeted edit preserves structure: \(ok)")
            }
        } else {
            print("(demo preset not found at \(path) — testing template instead)")
        }

        // Import the example .eproj project.
        let eprojPath = "../eventide_h9_max.eproj"
        if let text = try? String(contentsOfFile: eprojPath, encoding: .utf8) {
            print("isProject(eproj): \(PresetDocument.isProject(text))")
            if let doc = PresetDocument.load(fileText: text) {
                let controls = doc.allControls()
                print("Imported \"\(doc.name)\"  controls: \(controls.count)  lua: \(doc.lua != nil ? "\(doc.lua!.count) chars" : "none")")
                if let c = controls.first {
                    print("  first control: id=\(c.id) type=\(c.type) name=\"\(c.name)\" bounds=(\(Int(c.x)),\(Int(c.y)),\(Int(c.w)),\(Int(c.h))) set=\(c.controlSetId) pot=\(c.potId ?? -1)")
                }
                let types = Set(controls.map { $0.type }).sorted().joined(separator: ",")
                print("  control types: \(types)")
                print("  serialized preset re-parses: \(PresetDocument(jsonString: doc.jsonString()) != nil)")
                print("  no project keys leaked: \(!doc.jsonString().contains("\"tiles\"") && !doc.jsonString().contains("schemaVersion"))")
            } else {
                print("✗ failed to import eproj")
            }
        } else {
            print("(eproj example not found at \(eprojPath))")
        }

        // Template + addControl.
        var fresh = PresetDocument.newPreset(name: "Test")
        let id = fresh.addControl(pageId: 1)
        let c = fresh.control(id: id)
        print("New preset: control added id=\(id) type=\(c?.type ?? "?") bounds=(\(Int(c?.x ?? 0)),\(Int(c?.y ?? 0)),\(Int(c?.w ?? 0)),\(Int(c?.h ?? 0)))")
        print("Re-parse of serialized template valid: \(PresetDocument(jsonString: fresh.jsonString()) != nil)")
        print("✓ doc self-test done")
    }

    static func probeDevice() async {
        let device = E1Device()
        do {
            let ports = try await device.connect()
            print("Connected → in: \(ports.input) | out: \(ports.output)")

            let info = try await device.getInfo()
            print("Device   → \(info.modelUpper)  fw \(info.versionText ?? "?")  serial \(info.serial ?? "?")")

            print("Scanning bank 0 …")
            for slot in 0..<6 {
                let s = await device.scanSlot(bank: 0, slot: slot)
                let detail = s.name ?? s.error ?? "—"
                print(String(format: "  [%02d] %-7@ %@", slot, s.status.rawValue as NSString, detail))
            }

            // Round-trip a read of slot 1 to prove large fragmented reads work.
            if let summary = try? await device.summarize(bank: 0, slot: 1) {
                print("Slot 1   → \"\(summary.name)\"  controls: \(summary.controls)  pages: \(summary.pages)")
            }

            await device.disconnect()
            print("✓ probe completed")
        } catch {
            print("ERROR: \(error)")
            await device.disconnect()
            exit(1)
        }
    }
}
</file>

<file path="mac/Sources/ElectraOneApp/AppModel.swift">
import Foundation
import SwiftUI
import UniformTypeIdentifiers
import ElectraKit

/// UI state + orchestration. Published state lives on the main actor; MIDI work
/// happens on the `E1Device` actor. The app is document-centric: it always
/// edits a `PresetDocument`, which may originate from the device, a file, or a
/// fresh template. A device is optional — the editor works fully offline.
@MainActor
final class AppModel: ObservableObject {
    enum ConnectionState: Equatable {
        case connecting, ready, offline(String)
    }

    let slotsPerBank = 12
    let bankCount = 6

    private let device = E1Device()

    // Device
    @Published var connection: ConnectionState = .connecting
    @Published var info: DeviceInfo?
    @Published var portName: String = ""
    @Published var bank: Int = 0
    @Published var slots: [SlotState] = []
    @Published var openSlot: Int? = nil          // which device slot is loaded

    // Open document
    @Published var document: PresetDocument?
    @Published var fileURL: URL?
    @Published var deviceSlot: (bank: Int, slot: Int)?
    @Published var dirty = false
    @Published var currentPageId: Int = 1
    @Published var selectedControlId: Int? = nil

    // Status
    @Published var busy = false
    @Published var message: String = ""

    // Save-to-device sheet
    @Published var savePickerPresented = false
    @Published var saveBank = 0
    @Published var saveSlot = 0

    private var scanToken = 0

    init() {
        slots = (0..<slotsPerBank).map { SlotState(slot: $0, status: .unknown) }
    }

    var isConnected: Bool { if case .ready = connection { return true }; return false }

    var luaInfo: String? {
        guard let lua = document?.lua, !lua.isEmpty else { return nil }
        let lines = lua.split(whereSeparator: \.isNewline).count
        return "Lua script · \(lines) lines"
    }

    var documentTitle: String {
        guard let doc = document else { return "No preset open" }
        return doc.name.isEmpty ? "(unnamed)" : doc.name
    }

    var subtitle: String {
        var parts: [String] = []
        if let s = deviceSlot { parts.append("bank \(s.bank) · slot \(s.slot)") }
        if let u = fileURL { parts.append(u.lastPathComponent) }
        if dirty { parts.append("• edited") }
        return parts.joined(separator: "  ·  ")
    }

    // ── Connection (non-fatal) ─────────────────────────────────────────────

    func start() {
        Task {
            do {
                let ports = try await device.connect()
                portName = ports.input
                info = try await device.getInfo()
                connection = .ready
                rescan()
            } catch {
                connection = .offline(describe(error))
            }
        }
    }

    func reconnect() {
        connection = .connecting
        start()
    }

    func shutdown() { Task { await device.disconnect() } }

    // ── Device browser ───────────────────────────────────────────────────

    func setBank(_ newBank: Int) {
        guard newBank != bank, newBank >= 0, newBank < bankCount else { return }
        bank = newBank
        rescan()
    }

    func rescan() {
        guard isConnected else { return }
        scanToken += 1
        let token = scanToken
        let targetBank = bank
        slots = (0..<slotsPerBank).map { SlotState(slot: $0, status: .scanning) }
        Task {
            for slot in 0..<slotsPerBank {
                let result = await device.scanSlot(bank: targetBank, slot: slot)
                if token != scanToken { return }
                slots[slot] = result
            }
            if token == scanToken { message = "Scanned bank \(targetBank)." }
        }
    }

    func openFromSlot(_ slot: Int) {
        guard isConnected else { return }
        openSlot = slot
        let targetBank = bank
        busy = true
        message = "Loading bank \(targetBank), slot \(slot)…"
        Task {
            do {
                let raw = try await device.getPresetRaw(bank: targetBank, slot: slot)
                guard var doc = PresetDocument(jsonString: raw) else {
                    throw E1Error.decode("This slot's data isn't valid preset JSON.")
                }
                // Preserve any Lua so a later Save to Device doesn't drop it.
                if let lua = try? await device.getLua(bank: targetBank, slot: slot), !lua.isEmpty {
                    doc.lua = lua
                }
                loadDocument(doc, fileURL: nil, deviceSlot: (targetBank, slot))
                message = "Opened \"\(doc.name)\"."
            } catch let e as E1Error where isEmpty(e) {
                message = "Slot \(slot) is empty. Use New Preset to build one, then Save to Device."
            } catch {
                message = "Error: \(describe(error))"
            }
            busy = false
        }
    }

    // ── Document lifecycle ──────────────────────────────────────────────────

    private func loadDocument(_ doc: PresetDocument, fileURL: URL?, deviceSlot: (Int, Int)?) {
        document = doc
        self.fileURL = fileURL
        self.deviceSlot = deviceSlot.map { (bank: $0.0, slot: $0.1) }
        currentPageId = doc.pages.first?.id ?? 1
        selectedControlId = nil
        dirty = false
    }

    func newDocument() {
        loadDocument(.newPreset(), fileURL: nil, deviceSlot: nil)
        openSlot = nil
        message = "New preset."
    }

    func openFile() {
        let panel = NSOpenPanel()
        var types: [UTType] = [.json]
        if let eproj = UTType(filenameExtension: "eproj") { types.append(eproj) }
        if let epr = UTType(filenameExtension: "epr") { types.append(epr) }
        panel.allowedContentTypes = types
        panel.allowsOtherFileTypes = true
        panel.allowsMultipleSelection = false
        guard panel.runModal() == .OK, let url = panel.url else { return }
        do {
            let text = try String(contentsOf: url, encoding: .utf8)
            let wasProject = PresetDocument.isProject(text)
            guard let doc = PresetDocument.load(fileText: text) else {
                message = "Error: not a valid Electra preset or project file."
                return
            }
            // A project converts to a new preset; don't tie it to the source file.
            loadDocument(doc, fileURL: wasProject ? nil : url, deviceSlot: nil)
            openSlot = nil
            if wasProject {
                let n = doc.allControls().count
                let luaNote = doc.lua != nil ? " (with Lua script)" : ""
                message = "Imported project “\(doc.name)” — \(n) control(s)\(luaNote)."
            } else {
                message = "Opened \(url.lastPathComponent)."
            }
        } catch {
            message = "Error: \(error.localizedDescription)"
        }
    }

    func saveToFile() {
        guard let doc = document else { return }
        let url: URL
        if let existing = fileURL {
            url = existing
        } else {
            let panel = NSSavePanel()
            panel.allowedContentTypes = [.json]
            panel.nameFieldStringValue = PresetNaming.fileName(for: doc.name)
            panel.canCreateDirectories = true
            guard panel.runModal() == .OK, let chosen = panel.url else { return }
            url = chosen
        }
        do {
            try doc.jsonString(pretty: true).write(to: url, atomically: true, encoding: .utf8)
            fileURL = url
            dirty = false
            message = "Saved → \(url.path)"
        } catch {
            message = "Save failed: \(error.localizedDescription)"
        }
    }

    func saveToFileAs() {
        fileURL = nil
        saveToFile()
    }

    func presentSaveToDevice() {
        guard document != nil else { return }
        if let s = deviceSlot { saveBank = s.bank; saveSlot = s.slot }
        else { saveBank = bank; saveSlot = 0 }
        savePickerPresented = true
    }

    func confirmSaveToDevice() {
        savePickerPresented = false
        guard isConnected, let doc = document else {
            message = "Connect an Electra One to save to the device."
            return
        }
        let json = doc.jsonString(pretty: false)
        let lua = doc.lua
        let b = saveBank, s = saveSlot
        let luaNote = (lua?.isEmpty == false) ? " + Lua" : ""
        run("Uploading \"\(doc.name)\"\(luaNote) → bank \(b), slot \(s)…") {
            try await self.device.putProject(json: json, lua: lua, bank: b, slot: s)
            self.deviceSlot = (bank: b, slot: s)
            self.dirty = false
            if self.bank == b { self.rescan() }
            return "Saved \"\(doc.name)\"\(luaNote) → bank \(b), slot \(s)."
        }
    }

    // ── Editing ─────────────────────────────────────────────────────────────

    var currentControls: [PresetDocument.Control] {
        document?.controls(onPage: currentPageId) ?? []
    }

    var selectedControl: PresetDocument.Control? {
        guard let id = selectedControlId else { return nil }
        return document?.control(id: id)
    }

    private func edit(_ body: (inout PresetDocument) -> Void) {
        guard var doc = document else { return }
        body(&doc)
        document = doc
        dirty = true
    }

    func setControlName(_ id: Int, _ name: String) { edit { $0.setControlName(id: id, name) } }
    func setControlColor(_ id: Int, hex: String) { edit { $0.setControlColor(id: id, hex: hex) } }
    func setControlType(_ id: Int, _ type: String) { edit { $0.setControlType(id: id, type) } }
    func setControlParameterNumber(_ id: Int, _ n: Int) { edit { $0.setMessageParameterNumber(id: id, n) } }
    func setControlMessageType(_ id: Int, _ t: String) { edit { $0.setMessageType(id: id, t) } }

    func setControlBounds(_ id: Int, x: Double, y: Double, w: Double, h: Double) {
        edit { $0.setControlBounds(id: id, x: x, y: y, w: w, h: h) }
    }

    func setPresetName(_ name: String) { edit { $0.name = name } }
    func renamePage(_ id: Int, _ name: String) { edit { $0.renamePage(id: id, to: name) } }

    func addControl() {
        edit { doc in
            let newId = doc.addControl(pageId: currentPageId)
            DispatchQueue.main.async { self.selectedControlId = newId }
        }
        message = "Added control."
    }

    func deleteSelectedControl() {
        guard let id = selectedControlId else { return }
        edit { $0.removeControl(id: id) }
        selectedControlId = nil
        message = "Deleted control."
    }

    // ── Helpers ─────────────────────────────────────────────────────────────

    private func run(_ msg: String, _ op: @escaping () async throws -> String) {
        busy = true
        message = msg
        Task {
            do { message = try await op() }
            catch { message = "Error: \(describe(error))" }
            busy = false
        }
    }

    private func isEmpty(_ e: E1Error) -> Bool {
        if case .empty = e { return true }
        if case .timeout = e { return true }
        return false
    }

    private func describe(_ error: Error) -> String {
        (error as? E1Error)?.description ?? error.localizedDescription
    }
}

enum PresetNaming {
    static func fileName(for name: String?) -> String {
        let base = (name ?? "preset").trimmingCharacters(in: .whitespaces)
            .replacingOccurrences(of: "/", with: "_")
        return "\(base.isEmpty ? "preset" : base).json"
    }
}
</file>

<file path="mac/Sources/ElectraOneApp/ContentView.swift">
import SwiftUI
import ElectraKit
import UniformTypeIdentifiers

// ── Color helpers ──────────────────────────────────────────────────────────────

extension Color {
    init(electraHex hex: String) {
        var s = hex.hasPrefix("#") ? String(hex.dropFirst()) : hex
        if s.count == 3 { s = s.map { "\($0)\($0)" }.joined() }
        var v: UInt64 = 0
        Scanner(string: s).scanHexInt64(&v)
        self = Color(
            red: Double((v >> 16) & 0xff) / 255,
            green: Double((v >> 8) & 0xff) / 255,
            blue: Double(v & 0xff) / 255)
    }
}

// ── Root ───────────────────────────────────────────────────────────────────────

struct ContentView: View {
    @EnvironmentObject var model: AppModel

    var body: some View {
        NavigationSplitView {
            Sidebar().navigationSplitViewColumnWidth(min: 240, ideal: 270)
        } detail: {
            EditorPane()
        }
        .toolbar { toolbarContent }
        .sheet(isPresented: $model.savePickerPresented) { SaveToDeviceSheet() }
    }

    @ToolbarContentBuilder private var toolbarContent: some ToolbarContent {
        ToolbarItemGroup(placement: .navigation) {
            Button { model.newDocument() } label: { Label("New", systemImage: "doc.badge.plus") }
            Button { model.openFile() } label: { Label("Open", systemImage: "folder") }
        }
        ToolbarItemGroup(placement: .primaryAction) {
            Button { model.addControl() } label: { Label("Add Control", systemImage: "plus.app") }
                .disabled(model.document == nil)
            Button { model.saveToFile() } label: { Label("Save File", systemImage: "square.and.arrow.down") }
                .disabled(model.document == nil)
            Button { model.presentSaveToDevice() } label: { Label("Save to Device", systemImage: "arrow.up.circle") }
                .disabled(model.document == nil || !model.isConnected)
        }
    }
}

// ── Sidebar ──────────────────────────────────────────────────────────────────────

private struct Sidebar: View {
    @EnvironmentObject var model: AppModel

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            deviceHeader
            Divider()
            if model.isConnected {
                bankPicker
                Divider()
                slotList
            } else {
                offlineHint
                Spacer()
            }
        }
    }

    @ViewBuilder private var deviceHeader: some View {
        VStack(alignment: .leading, spacing: 3) {
            switch model.connection {
            case .connecting:
                Label("Connecting…", systemImage: "bolt.horizontal.circle").font(.headline)
            case .offline:
                HStack {
                    Label("No device", systemImage: "cable.connector.slash")
                        .font(.headline).foregroundStyle(.secondary)
                    Spacer()
                    Button("Retry") { model.reconnect() }.controlSize(.small)
                }
            case .ready:
                Text("Electra One \(model.info?.modelUpper ?? "")").font(.headline)
                Text("fw \(model.info?.versionText ?? "?")  ·  \(model.info?.serial ?? "")")
                    .font(.caption).foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
    }

    private var offlineHint: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Editing offline").font(.subheadline.bold())
            Text("Create or open a preset to build it visually. Connect an Electra One to load and save presets on the device.")
                .font(.caption).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
            HStack {
                Button { model.newDocument() } label: { Label("New", systemImage: "doc.badge.plus") }
                Button { model.openFile() } label: { Label("Open", systemImage: "folder") }
            }
            .controlSize(.small)
        }
        .padding(12)
    }

    private var bankPicker: some View {
        HStack {
            Text("Bank").font(.subheadline.bold())
            Picker("Bank", selection: Binding(get: { model.bank }, set: { model.setBank($0) })) {
                ForEach(0..<model.bankCount, id: \.self) { Text("\($0)").tag($0) }
            }
            .labelsHidden().pickerStyle(.segmented)
        }
        .padding(.horizontal, 12).padding(.vertical, 8)
    }

    private var slotList: some View {
        List(selection: Binding(get: { model.openSlot }, set: { if let s = $0 { model.openFromSlot(s) } })) {
            Section("Presets") {
                ForEach(model.slots) { slot in
                    SlotRow(slot: slot).tag(slot.slot)
                }
            }
        }
        .listStyle(.sidebar)
    }
}

private struct SlotRow: View {
    let slot: SlotState
    var body: some View {
        HStack(spacing: 8) {
            Text(String(format: "%02d", slot.slot))
                .font(.system(.body, design: .monospaced)).foregroundStyle(.secondary)
            switch slot.status {
            case .ok:       Text(slot.name ?? "(unnamed)")
            case .empty:    Text("—").foregroundStyle(.tertiary)
            case .scanning: Text("scanning…").italic().foregroundStyle(.secondary)
            case .error:    Label("corrupt", systemImage: "exclamationmark.triangle")
                                .foregroundStyle(.orange).labelStyle(.titleAndIcon)
            case .unknown:  Text("·").foregroundStyle(.tertiary)
            }
            Spacer()
        }
        .padding(.vertical, 1)
    }
}

// ── Editor pane ───────────────────────────────────────────────────────────────────

private struct EditorPane: View {
    @EnvironmentObject var model: AppModel

    var body: some View {
        if model.document == nil {
            WelcomeView()
        } else {
            VStack(spacing: 0) {
                EditorHeader()
                Divider()
                HStack(spacing: 0) {
                    PresetCanvas()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color(nsColor: .underPageBackgroundColor))
                    Divider()
                    Inspector().frame(width: 290)
                }
                Divider()
                StatusBar()
            }
        }
    }
}

private struct WelcomeView: View {
    @EnvironmentObject var model: AppModel
    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: "slider.horizontal.2.square").font(.system(size: 54)).foregroundStyle(.secondary)
            Text("Electra One Preset Editor").font(.title2.bold())
            Text(model.isConnected
                 ? "Pick a preset slot on the left to edit it, or start a new one."
                 : "Build a preset offline, or connect an Electra One to load one.")
                .foregroundStyle(.secondary).multilineTextAlignment(.center)
            HStack {
                Button { model.newDocument() } label: { Label("New Preset", systemImage: "doc.badge.plus") }
                    .buttonStyle(.borderedProminent)
                Button { model.openFile() } label: { Label("Open File…", systemImage: "folder") }
            }
        }
        .padding(50).frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private struct EditorHeader: View {
    @EnvironmentObject var model: AppModel
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                TextField("Preset name", text: Binding(
                    get: { model.document?.name ?? "" },
                    set: { model.setPresetName($0) }))
                    .textFieldStyle(.plain).font(.title.bold())
                Spacer()
            }
            if !model.subtitle.isEmpty {
                Text(model.subtitle).font(.caption).foregroundStyle(.secondary)
            }
            PageTabs()
        }
        .padding(.horizontal, 16).padding(.vertical, 12)
    }
}

private struct PageTabs: View {
    @EnvironmentObject var model: AppModel
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(model.document?.pages ?? []) { page in
                    let on = page.id == model.currentPageId
                    Button {
                        model.currentPageId = page.id
                        model.selectedControlId = nil
                    } label: {
                        Text(page.name)
                            .font(.callout.weight(on ? .semibold : .regular))
                            .padding(.horizontal, 12).padding(.vertical, 5)
                            .background(on ? Color.accentColor.opacity(0.18) : Color.clear)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

// ── The Electra "screen" ─────────────────────────────────────────────────────────

private struct PresetCanvas: View {
    @EnvironmentObject var model: AppModel

    var body: some View {
        GeometryReader { geo in
            let scale = min(geo.size.width / PresetDocument.screenWidth,
                            geo.size.height / PresetDocument.screenHeight)
            let cw = PresetDocument.screenWidth * scale
            let ch = PresetDocument.screenHeight * scale
            ZStack {
                Color.clear
                ZStack(alignment: .topLeading) {
                    Rectangle().fill(Color.black)
                        .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color.white.opacity(0.08)))
                        .onTapGesture { model.selectedControlId = nil }
                    ForEach(model.currentControls) { control in
                        ControlCell(
                            control: control,
                            scale: scale,
                            selected: model.selectedControlId == control.id,
                            onSelect: { model.selectedControlId = control.id },
                            onMove: { dx, dy in
                                let nx = max(0, min(PresetDocument.screenWidth - control.w, control.x + dx))
                                let ny = max(0, min(PresetDocument.screenHeight - control.h, control.y + dy))
                                model.setControlBounds(control.id, x: nx, y: ny, w: control.w, h: control.h)
                            })
                    }
                    if model.currentControls.isEmpty {
                        Text("No controls on this page.\nUse “Add Control” to place one.")
                            .multilineTextAlignment(.center)
                            .foregroundStyle(.white.opacity(0.4))
                            .frame(width: cw, height: ch)
                    }
                }
                .frame(width: cw, height: ch)
                .clipped()
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .padding(16)
    }
}

private struct ControlCell: View {
    let control: PresetDocument.Control
    let scale: Double
    let selected: Bool
    let onSelect: () -> Void
    let onMove: (Double, Double) -> Void

    @State private var drag: CGSize = .zero

    private var color: Color { Color(electraHex: control.colorHex) }
    private var w: CGFloat { control.w * scale }
    private var h: CGFloat { control.h * scale }

    var body: some View {
        cell
            .frame(width: w, height: h)
            .position(x: (control.x + control.w / 2) * scale + drag.width,
                      y: (control.y + control.h / 2) * scale + drag.height)
            .gesture(
                DragGesture(minimumDistance: 3)
                    .onChanged { drag = $0.translation }
                    .onEnded { v in onMove(Double(v.translation.width) / scale, Double(v.translation.height) / scale); drag = .zero }
            )
            .onTapGesture { onSelect() }
    }

    @ViewBuilder private var cell: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.white.opacity(0.04))
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(selected ? Color.white : color.opacity(0.5),
                                lineWidth: selected ? 2 : 1))
            VStack(spacing: 2) {
                Text(control.name.isEmpty ? control.type : control.name)
                    .font(.system(size: max(7, 11 * scale * 1.6), weight: .semibold))
                    .foregroundStyle(color)
                    .lineLimit(1)
                    .padding(.top, 3)
                graphic
                Spacer(minLength: 0)
            }
            .padding(3)
        }
    }

    @ViewBuilder private var graphic: some View {
        switch control.type {
        case "pad":
            RoundedRectangle(cornerRadius: 3)
                .fill(color.opacity(0.35))
                .overlay(RoundedRectangle(cornerRadius: 3).stroke(color, lineWidth: 1))
                .frame(maxWidth: .infinity)
                .frame(height: max(8, h * 0.4))
        case "list":
            RoundedRectangle(cornerRadius: 2)
                .stroke(color.opacity(0.7))
                .overlay(Text("▾").font(.system(size: max(7, 9 * scale * 1.4))).foregroundStyle(color))
                .frame(height: max(8, h * 0.35))
        default: // fader / dial / others
            VStack(spacing: 2) {
                Spacer(minLength: 0)
                GeometryReader { g in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color.white.opacity(0.12))
                        Capsule().fill(color).frame(width: g.size.width * fillFraction)
                    }
                }
                .frame(height: max(4, 6 * scale * 1.4))
                Text(valueLabel)
                    .font(.system(size: max(6, 8 * scale * 1.4), design: .monospaced))
                    .foregroundStyle(.white.opacity(0.6))
            }
        }
    }

    private var fillFraction: CGFloat {
        let lo = Double(control.minValue ?? 0)
        let hi = Double(control.maxValue ?? 127)
        guard hi > lo else { return 0.5 }
        return 0.6 // representative; we don't track live values offline
    }

    private var valueLabel: String {
        if let p = control.parameterNumber, let t = control.messageType {
            return "\(t) \(p)"
        }
        return control.messageType ?? ""
    }
}

// ── Inspector ─────────────────────────────────────────────────────────────────────

private struct Inspector: View {
    @EnvironmentObject var model: AppModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                if let c = model.selectedControl {
                    controlInspector(c)
                } else {
                    presetInspector
                }
            }
            .padding(14)
        }
    }

    @ViewBuilder private var presetInspector: some View {
        Text("Preset").font(.headline)
        labeled("Name") {
            TextField("Name", text: Binding(get: { model.document?.name ?? "" }, set: { model.setPresetName($0) }))
        }
        if let page = (model.document?.pages.first { $0.id == model.currentPageId }) {
            labeled("Current page") {
                TextField("Page name", text: Binding(get: { page.name }, set: { model.renamePage(page.id, $0) }))
            }
        }
        if let lua = model.luaInfo {
            Label(lua, systemImage: "curlybraces.square")
                .font(.caption).foregroundStyle(.purple)
        }
        Divider()
        Text("\(model.currentControls.count) control(s) on this page")
            .font(.caption).foregroundStyle(.secondary)
        Text("Select a control to edit it, or “Add Control” to place a new one. Drag controls to reposition.")
            .font(.caption).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
    }

    @ViewBuilder private func controlInspector(_ c: PresetDocument.Control) -> some View {
        HStack {
            Text("Control").font(.headline)
            Spacer()
            Button(role: .destructive) { model.deleteSelectedControl() } label: {
                Image(systemName: "trash")
            }.buttonStyle(.borderless)
        }
        labeled("Name") {
            TextField("Name", text: Binding(get: { c.name }, set: { model.setControlName(c.id, $0) }))
        }
        labeled("Type") {
            Picker("", selection: Binding(get: { c.type }, set: { model.setControlType(c.id, $0) })) {
                ForEach(["fader", "pad", "list"], id: \.self) { Text($0.capitalized).tag($0) }
            }.labelsHidden()
        }
        labeled("Color") {
            HStack(spacing: 6) {
                ForEach(PresetDocument.palette, id: \.self) { hex in
                    Circle().fill(Color(electraHex: hex))
                        .frame(width: 20, height: 20)
                        .overlay(Circle().stroke(Color.primary.opacity(c.colorHex.caseInsensitiveCompare(hex) == .orderedSame ? 0.9 : 0.15), lineWidth: 2))
                        .onTapGesture { model.setControlColor(c.id, hex: hex) }
                }
            }
        }
        Divider()
        Text("MIDI").font(.subheadline.bold())
        labeled("Message") {
            Picker("", selection: Binding(get: { c.messageType ?? "cc7" }, set: { model.setControlMessageType(c.id, $0) })) {
                ForEach(["cc7", "cc14", "nrpn", "rpn", "note", "program", "start", "stop"], id: \.self) { Text($0).tag($0) }
            }.labelsHidden()
        }
        labeled("Parameter #") {
            TextField("", value: Binding(
                get: { c.parameterNumber ?? 0 },
                set: { model.setControlParameterNumber(c.id, $0) }), format: .number)
        }
        Divider()
        Text("Position").font(.subheadline.bold())
        HStack {
            numField("X", c.x) { model.setControlBounds(c.id, x: $0, y: c.y, w: c.w, h: c.h) }
            numField("Y", c.y) { model.setControlBounds(c.id, x: c.x, y: $0, w: c.w, h: c.h) }
        }
        HStack {
            numField("W", c.w) { model.setControlBounds(c.id, x: c.x, y: c.y, w: $0, h: c.h) }
            numField("H", c.h) { model.setControlBounds(c.id, x: c.x, y: c.y, w: c.w, h: $0) }
        }
    }

    private func labeled<V: View>(_ title: String, @ViewBuilder _ content: () -> V) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title).font(.caption).foregroundStyle(.secondary)
            content()
        }
    }

    private func numField(_ label: String, _ value: Double, _ set: @escaping (Double) -> Void) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(label).font(.caption).foregroundStyle(.secondary)
            TextField("", value: Binding(get: { Int(value) }, set: { set(Double($0)) }), format: .number)
        }
    }
}

// ── Status bar + sheets ────────────────────────────────────────────────────────────

private struct StatusBar: View {
    @EnvironmentObject var model: AppModel
    var body: some View {
        HStack(spacing: 8) {
            if model.busy { ProgressView().controlSize(.small) }
            Text(model.message.isEmpty ? " " : model.message)
                .font(.callout).lineLimit(1)
                .foregroundStyle(model.message.hasPrefix("Error") ? .red : .secondary)
            Spacer()
        }
        .padding(.horizontal, 16).padding(.vertical, 8)
    }
}

private struct SaveToDeviceSheet: View {
    @EnvironmentObject var model: AppModel
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Save to Device").font(.headline)
            Text("Upload “\(model.documentTitle)” to a slot. This overwrites whatever is there.")
                .font(.callout).foregroundStyle(.secondary)
            HStack(spacing: 20) {
                Stepper("Bank \(model.saveBank)", value: $model.saveBank, in: 0...(model.bankCount - 1))
                Stepper("Slot \(model.saveSlot)", value: $model.saveSlot, in: 0...(model.slotsPerBank - 1))
            }
            HStack {
                Spacer()
                Button("Cancel") { model.savePickerPresented = false }.keyboardShortcut(.cancelAction)
                Button("Upload") { model.confirmSaveToDevice() }.keyboardShortcut(.defaultAction).buttonStyle(.borderedProminent)
            }
        }
        .padding(20).frame(width: 380)
    }
}
</file>

<file path="mac/README.md">
# Electra One — native macOS app

A SwiftUI **visual preset editor** for the Electra One. Renders presets like the
device screen (pages, controls laid out by their bounds/color/type), and lets
you build and edit them **with or without hardware connected**. When a device
is attached over USB it also browses, loads, and saves presets on it. Same
protocol as the Node CLI/TUI in the repo root, reimplemented natively over
CoreMIDI (no Node required).

## What it does

- **Visual editor** — a black "screen" canvas draws each control at its real
  `bounds` with its color and a type-specific graphic (fader bar, pad, list).
  Page tabs switch pages. Drag a control to reposition it.
- **Inspector** — select a control to edit its name, color (Electra palette),
  type, MIDI message (cc7/cc14/nrpn/note/program/…), parameter number, and
  exact position. Add/delete controls. Rename the preset and pages.
- **Offline** — New Preset / Open File… work with no device. Save to a `.json`
  file. Editing preserves every field of the original JSON, so round-tripping
  never corrupts a preset.
- **Imports `.eproj` projects** — open an Electra web-editor project and it's
  converted to the editable preset model: `tiles` → controls, `slotId` →
  pixel bounds + page/control-set/pot, and the embedded Lua script is carried
  along. Saving to the device uploads the preset **and** the Lua.
- **With a device** — browse banks/slots, click a slot to open it in the
  editor, and Save to Device (pick bank/slot) to upload.

## Build & run

```bash
cd mac
./build-app.sh            # release build → ElectraOne.app (ad-hoc signed)
open ./ElectraOne.app
```

For development:

```bash
swift run ElectraOneApp   # run the app directly
swift run e1probe         # headless: connect, read info, scan bank 0
swift build               # compile everything
```

Requires the Swift toolchain (Swift 5.9+/6.x; the Xcode Command Line Tools are
enough — no full Xcode needed). Targets macOS 13+.

## Layout

| Target | Role |
|--------|------|
| `ElectraKit` | MIDI transport (CoreMIDI), SysEx protocol, `E1Device` actor |
| `ElectraOneApp` | SwiftUI front-end (`AppModel`, `ContentView`) |
| `e1probe` | headless connection/scan check for verifying the hardware link |

## How it talks to the device

- **`MIDITransport`** opens the `Electra … CTRL` source/destination once,
  reassembles fragmented SysEx until `F7`, and sends via `MIDISend` (CoreMIDI
  splits large uploads on the wire). Exchanges are serialized by the
  `E1Device` actor.
- **`E1Proto`** builds/decodes the SysEx (manufacturer `00 21 45`). Requests
  use op `0x02`; uploads (op `0x01`) target the **active** slot, so
  `putPreset` arms the slot first with `0x14 0x08 bank slot`. ACK = `7E 01`,
  NACK = `7E 00`; other `7E` codes (e.g. `05`) are notifications and ignored.
- Editing shows the preset JSON in a built-in editor; **Save to Device**
  validates the JSON and uploads it to the slot. Empty slots are detected by a
  zero-length response.
</file>

</files>
