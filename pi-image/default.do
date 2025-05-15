
TARGET="${2}.vault"

if ! test -f "$TARGET"
then
    echo >&2 "encrypted file $TARGET does not exist"
    exit 1
fi

if test -z "$ANSIBLE_VAULT_PASSWORD_FILE"
then
    echo >&2 "environment variable ANSIBLE_VAULT_PASSWORD_FILE is required to decrypt $TARGET"
    exit 1
fi

ansible-vault decrypt --output "$3" "$TARGET"
