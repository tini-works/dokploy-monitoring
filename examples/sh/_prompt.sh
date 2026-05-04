#!/usr/bin/env bash
# Sourced by send-test-*.sh — prompts for Alloy credentials if unset.

if [ -z "${ALLOY_ENDPOINT:-}" ]; then
  read -rp "Alloy endpoint (e.g. https://alloy.example.com): " ALLOY_ENDPOINT
fi
if [ -z "${ALLOY_USER:-}" ]; then
  read -rp "Alloy user: " ALLOY_USER
fi
if [ -z "${ALLOY_PASSWORD:-}" ]; then
  read -rsp "Alloy password: " ALLOY_PASSWORD
  echo ""
fi
