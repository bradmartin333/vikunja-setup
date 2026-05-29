#!/bin/bash

# Define the state file to store previous runs
STATE_FILE=".vikunja_user_deltas.state"
TMP_STATE="${STATE_FILE}.tmp"

# Initialize an associative array to hold the previous state
declare -A prev_deltas

# Load the previous state if the file exists
if [[ -f "$STATE_FILE" ]]; then
    while IFS='=' read -r stored_user stored_delta; do
        prev_deltas["$stored_user"]="$stored_delta"
    done < "$STATE_FILE"
fi

# Clear or create the temporary state file for this run
> "$TMP_STATE"

# Helper function to format seconds into a human-readable string
format_delta() {
    local d=$1
    local hours=$(( d / 3600 ))
    local mins=$(( (d % 3600) / 60 ))
    local secs=$(( d % 60 ))
    local str=""
    (( hours > 0 )) && str+="${hours}h "
    (( mins > 0 )) && str+="${mins}m "
    str+="${secs}s"
    echo "$str"
}

# Execute the Docker command and pipe the output
docker exec -it "vikunja-vikunja-1" /app/vikunja/vikunja user list | \
awk -F '│' 'NF>8 && $2 ~ /[0-9]/ {print $3, $8, $9}' | \
while read -r raw_user raw_created raw_updated; do
    
    # Safely extract standard date format
    created=$(echo "$raw_created" | grep -oE '[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z')
    updated=$(echo "$raw_updated" | grep -oE '[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z')
    user=$(echo "$raw_user" | sed 's/[^a-zA-Z0-9_.-]//g')
    
    if [[ -z "$created" || -z "$updated" ]]; then
        continue
    fi

    if [[ "$created" != "$updated" ]]; then
        t1=$(date -d "$created" +%s)
        t2=$(date -d "$updated" +%s)
        
        delta=$(( t2 - t1 ))
        if (( delta < 0 )); then delta=$(( -delta )); fi
        
        # Ignore deltas less than 5 seconds
        if (( delta >= 5 )); then
            
            # Save this user's delta to the new state file
            echo "$user=$delta" >> "$TMP_STATE"
            
            delta_str=$(format_delta "$delta")
            prev_d="${prev_deltas["$user"]}"
            
            echo "Username: $user"
            echo "Created:  $created"
            echo "Updated:  $updated"
            
            # Compare current delta to previous delta
            if [[ -z "$prev_d" ]]; then
                echo "Delta:    $delta_str (NEW)"
            elif (( prev_d != delta )); then
                prev_str=$(format_delta "$prev_d")
                echo "Delta:    $delta_str (CHANGED from $prev_str)"
            else
                echo "Delta:    $delta_str (Unchanged)"
            fi
            echo "---------------------------------"
        fi
    fi
done

# Replace the old state file with the updated one
mv "$TMP_STATE" "$STATE_FILE"
