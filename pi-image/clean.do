rm -f *.xz *.img

for f in $(ls *.vault)
do
    rm -f $(basename -s.vault $f)
done
