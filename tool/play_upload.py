#!/usr/bin/env python3
"""Upload a release AAB to a Google Play *testing* track.

Guard rails:
- only the internal, alpha and beta tracks are allowed (never production);
- releases are created as drafts unless --status completed is passed;
- the release name and versionCode come from pubspec.yaml, and the upload is
  refused if the AAB's versionCode doesn't match;
- the Play edit is deleted if anything fails, so nothing half-done is left.

The service-account key is read from a file path and never printed. It
should only have "release to testing tracks" for this app. Pass the path with
--key or set PLAY_SERVICE_ACCOUNT_KEY; keep the JSON outside the repo.

Usage:
  export PLAY_SERVICE_ACCOUNT_KEY=/path/outside/the/repo/play-publisher.json
  python3 tool/play_upload.py \
      --aab build/app/outputs/bundle/release/app-release.aab \
      --notes "What changed" [--track internal] [--status draft|completed] \
      [--pubspec pubspec.yaml] [--package space.d11s.niceproportions] [--dry-run]

Needs: pip install google-api-python-client google-auth
"""
import argparse
import os
import re
import sys

ALLOWED_TRACKS = ("internal", "alpha", "beta")


def pubspec_version(path):
    with open(path, encoding="utf-8") as f:
        for line in f:
            m = re.match(r"^version:\s*([0-9A-Za-z.\-]+)\+(\d+)\s*$", line)
            if m:
                return m.group(1), int(m.group(2))
    sys.exit(f"No 'version: x.y.z+N' line found in {path}")


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--key", default=os.environ.get("PLAY_SERVICE_ACCOUNT_KEY"),
                    help="service-account JSON key file (default: $PLAY_SERVICE_ACCOUNT_KEY)")
    ap.add_argument("--aab", required=True)
    ap.add_argument("--notes", required=True, help="release notes (default listing language)")
    ap.add_argument("--track", default="internal", choices=ALLOWED_TRACKS)
    ap.add_argument("--status", default="draft", choices=("draft", "completed"))
    ap.add_argument("--pubspec", default="pubspec.yaml")
    ap.add_argument("--package", default="space.d11s.niceproportions")
    ap.add_argument("--dry-run", action="store_true",
                    help="check access and the track, then discard the edit without uploading")
    a = ap.parse_args()
    if not a.key:
        ap.error("no service-account key: pass --key or set PLAY_SERVICE_ACCOUNT_KEY")

    from google.oauth2 import service_account
    from googleapiclient.discovery import build
    from googleapiclient.http import MediaFileUpload

    name, code = pubspec_version(a.pubspec)
    creds = service_account.Credentials.from_service_account_file(
        a.key, scopes=["https://www.googleapis.com/auth/androidpublisher"])
    edits = build("androidpublisher", "v3", credentials=creds, cache_discovery=False).edits()

    edit = edits.insert(packageName=a.package, body={}).execute()["id"]
    committed = False
    try:
        lang = edits.details().get(packageName=a.package, editId=edit).execute().get("defaultLanguage", "en-US")
        edits.tracks().get(packageName=a.package, editId=edit, track=a.track).execute()
        if a.dry_run:
            print(f"dry run ok: {a.package}, track {a.track}, would upload {name} ({code}) as {a.status}")
            return
        bundle = edits.bundles().upload(
            packageName=a.package, editId=edit,
            media_body=MediaFileUpload(a.aab, mimetype="application/octet-stream", resumable=True)).execute()
        if int(bundle["versionCode"]) != code:
            raise SystemExit(f"AAB versionCode {bundle['versionCode']} doesn't match pubspec {code}; not releasing")
        edits.tracks().update(packageName=a.package, editId=edit, track=a.track, body={
            "track": a.track,
            "releases": [{
                "name": name,
                "versionCodes": [str(code)],
                "status": a.status,
                "releaseNotes": [{"language": lang, "text": a.notes}],
            }],
        }).execute()
        edits.commit(packageName=a.package, editId=edit).execute()
        committed = True
        print(f"committed {name} ({code}) to {a.track} as {a.status} [{lang}]")
    finally:
        if not committed:
            try:
                edits.delete(packageName=a.package, editId=edit).execute()
                print("edit discarded")
            except Exception as e:  # already gone or expired
                print(f"could not delete edit: {type(e).__name__}")


if __name__ == "__main__":
    main()
