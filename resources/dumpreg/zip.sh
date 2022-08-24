#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$DIR"

zip -r marc21.zip marc21
zip -r normarc.zip normarc

