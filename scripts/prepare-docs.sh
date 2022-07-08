#!/usr/bin/env bash

set -o errexit

OUTDIR=docs/api/

if [ ! -d node_modules ]; then
  npm ci
fi

rm -rf "$OUTDIR"
npx solidity-docgen \
  -t docs \
  -o "$OUTDIR" \
  -e contracts/mocks \
  --solc-module solc-0.6.12 \
  --output-structure contracts

# remove some
files=( "libs" "ILedger.md"  \
       "Proxyable.md" "ExchangeStore.md" "IExchange.md" "ISubLedger.md" "LedgerStore.md" \
      "IFeePlan.md" "IVotePool.md" "Migrations.md" "VotePoolStore.md" "FeePlanStore.md")

for file in "${files[@]}"
do
  rm -rf "$OUTDIR/$file"
done
