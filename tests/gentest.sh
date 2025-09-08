#!/bin/bash

# Output file
output_file="test_file.bin"

# Remove the output file if it already exists
rm -f "$output_file"

# Generate 20 records (0x00 to 0x14)
for i in $(seq 0 19); do
    # Convert the record number to a 2-character hex string
    hex=$(printf "%02X" "$i")

    # Fixed string "XXXXX" (5 bytes)
    fixed="XXXXX"

    # Create a random ASCII string to fill the remaining bytes (505 bytes)
    random_data=$(cat /dev/urandom | tr -dc 'A-Za-z0-9!@#$%^&*()-_=+[]{}|;:,.<>?/' | head -c $((512 - 2 - ${#fixed})))

    # Combine the hex, fixed string, and random data to form the 512-byte record
    record=$(printf "%s%s%s" "$hex" "$fixed" "$random_data")

    # Write the record to the binary file
    echo -n "$record" >> "$output_file"
done

# Confirm creation
echo "Binary test file created: $output_file"

