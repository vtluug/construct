# Vesuvius
Giant storage server + future LHCPISCSIPXEIDK thing maybe?

## TODO:
- The whole netboot thing
- Other stuff (maybe some meta nixy stuff? we've got room)
- Something beautifully stupid that uses comical amounts of storage
- Maybe move FreeIPA to a general modules directory

## Storage
We currently have one (manually created) RAID-Z2 pool mounted at `/forge` with `8` drives of `12 Tb` each.
We have capacity for `48`(!) drives, but still only paper (and tape) caddies.

```
# for the nix store
zfs create -o mountpoint=legacy \
           -o compression=zstd \
           -o xattr=sa \
           -o acltype=posixacl \
           -o atime=off \
           forge/nix
```