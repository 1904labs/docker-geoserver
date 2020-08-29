#!/bin/bash
set -e

source update_passwords.sh

exec "$@"
