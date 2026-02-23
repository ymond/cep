#!/usr/bin/env bash
# Run all CEP test suites. Exit with failure if any suite fails.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

overall_exit=0

for test_file in "$SCRIPT_DIR"/test_*.sh; do
    if ! bash "$test_file"; then
        overall_exit=1
    fi
done

echo ""
if [[ $overall_exit -eq 0 ]]; then
    echo -e "\033[0;32mAll test suites passed.\033[0m"
else
    echo -e "\033[0;31mSome test suites failed.\033[0m"
fi

exit $overall_exit
