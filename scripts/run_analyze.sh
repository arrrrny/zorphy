#!/bin/bash
export PATH=/opt/flutter/bin:$PATH
cd /workspace/zorphy/zorphy
dart analyze --format machine 2>&1 | grep "^ERROR" | cut -d'|' -f3 | sort | uniq -c | sort -rn > /tmp/error_counts.txt
dart analyze --format machine 2>&1 | grep -c "^ERROR" > /tmp/error_total.txt
echo "done"
