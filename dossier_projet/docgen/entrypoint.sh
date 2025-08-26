#!/bin/bash
set -e

# Get host user's UID and GID
USER_ID=${HOST_UID:-1000}
GROUP_ID=${HOST_GID:-1000}

echo "Starting with UID: $USER_ID, GID: $GROUP_ID"

# Create the group if it doesn't exist
if ! getent group $GROUP_ID > /dev/null; then
    groupadd -g $GROUP_ID usergroup
fi

# Create the user if it doesn't exist
if ! getent passwd $USER_ID > /dev/null; then
    useradd -u $USER_ID -g $GROUP_ID -m -s /bin/bash user
fi

# Give user access to necessary directories
chown -R $USER_ID:$GROUP_ID /workdir

# Make Chrome accessible to the user
mkdir -p /home/user/.cache/puppeteer
chown -R $USER_ID:$GROUP_ID /home/user

# Run the process_and_compile.sh script as the user
exec gosu $USER_ID:$GROUP_ID /usr/local/bin/process_and_compile.sh "$@"