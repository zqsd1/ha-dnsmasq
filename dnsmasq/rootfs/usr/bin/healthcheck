#! /usr/bin/env bash

#will fail if no file found
UUID=$(</data/matter_access_point_uuid)
if [[ -z $(nmcli -g connection.interface-name con show "$UUID" ) ]]; then
    #fail if the connection is not in use
    exit 1
fi
exit 0