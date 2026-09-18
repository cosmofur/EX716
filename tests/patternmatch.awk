#!/usr/bin/awk -f

# This AWK script buffers lines that end with a backslash (\) as a group.
# If the PATTERN (passed via -v) is found in any line of the group,
# the entire group is printed.

BEGIN {
    # Initialize buffer index (AWK arrays start at 1, so 1 is a good start)
    i = 1; 
    
    # Flag to track if the PATTERN has been found within the current group
    match_found = 0; 
    
    # Ensure PATTERN is set, though it should be passed via -v
    if (PATTERN == "") {
        # PATTERN must be defined for the script to function correctly
        print "Error: PATTERN variable is not set. Usage: awk -v PATTERN=\"...\" -f group_grep.awk input_file" > "/dev/stderr";
        exit 1;
    }
}

# Main processing block: runs for every line of input
{
    # 1. Store the current line in the buffer
    buffer[i++] = $0;

    # 2. Check if the pattern matches the current line.
    # $0 ~ PATTERN checks if the whole line contains the pattern (regex supported).
    if ($0 ~ PATTERN) {
        match_found = 1;
    }

    # 3. Check if the current line ends the continuation group.
    # The group ends if the line does NOT end with a literal backslash (\).
    if ($0 !~ /\\$/) {
        # --- End of Group Detected ---

        # 4. If a match was found anywhere in this group, print the entire buffer
        if (match_found) {
            # Print from the first index (1) up to the last index (i-1)
            for (j = 1; j < i; j++) {
                print buffer[j];
            }
        }

        # 5. Reset the state for the next group
        match_found = 0;
        i = 1; # Reset buffer index to start a new group
        
        # NOTE: We do not clear the buffer array as the next lines will overwrite it
        # starting from index 1.
    }
}
