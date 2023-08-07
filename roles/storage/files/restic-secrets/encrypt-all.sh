#! /bin/sh
#
find . -type f \
  | grep -v -e 'encrypt-all.sh' -e '\.vault$' -e '\.gitignore' \
| while read FILE
do
  if ! test -f "$FILE".vault
  then
    echo >&2 "Encrypting $FILE:"
    ansible-vault encrypt --output "$FILE".vault "$FILE"
  else
    echo >&2 "$FILE already encrypted, skipping; delete ${FILE}.vault to rekey"
  fi
done


