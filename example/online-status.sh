#!/bin/bash
# From https://gist.github.com/remy/6079223#file-online-check-sh
# In your statusline, run `cashe read online-status` to get the current online
# status.
dig 8.8.8.8 +time=1 +short google.com A | grep -c "no servers could be reached"
