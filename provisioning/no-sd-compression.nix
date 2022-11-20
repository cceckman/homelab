# Don't compress the SD image; we're going to pull it out anyway.
{ ... } : { sdImage.compressImage = false; }
