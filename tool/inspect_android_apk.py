#!/usr/bin/env python3
"""Inspect/copy a debug test APK. Never installs, signs or modifies Android data."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import shutil
import subprocess


def run(*args):
    return subprocess.check_output(args, text=True, stderr=subprocess.STDOUT)


def sha256(path):
    with path.open('rb') as stream:
        return hashlib.file_digest(stream, 'sha256').hexdigest()

def inspect(apk, tools):
    badging = run(str(tools / 'aapt'), 'dump', 'badging', str(apk))
    signature = run(str(tools / 'apksigner'), 'verify', '--verbose', '--print-certs', str(apk))
    package = re.search(r"^package: name='([^']+)' versionCode='(\d+)' versionName='([^']+)'", badging, re.M)
    certificate = re.findall(r'^Signer #\d+ certificate SHA-256 digest: ([0-9a-fA-F]{64})$', signature, re.M)
    if package is None or package[1] != 'mz.lifeos.lifeos':
        raise ValueError('Unexpected application ID; no test artifact prepared')
    if 'application-debuggable' not in badging.splitlines():
        raise ValueError('APK is not debuggable; no production APK may be prepared by this tool')
    if len(certificate) != 1:
        raise ValueError('Expected exactly one verified signing certificate')
    sdk = lambda key: re.search(rf"^{key}:'([^']+)'", badging, re.M)[1]
    activity = re.search(r"^launchable-activity: name='([^']+)'", badging, re.M)
    abi = re.search(r"^native-code: (.+)$", badging, re.M)
    metadata = {
        'application_id': package[1], 'version_code': int(package[2]), 'version_name': package[3],
        'min_sdk': int(sdk('sdkVersion')), 'target_sdk': int(sdk('targetSdkVersion')),
        'debuggable': True, 'signature_verified': True,
        'signer_certificate_sha256': certificate[0].lower(),
        'launchable_activity': activity[1] if activity else None,
        'abis': re.findall(r"'([^']+)'", abi[1]) if abi else [],
        'apk_filename': 'app-debug.apk', 'apk_bytes': apk.stat().st_size,
        'apk_sha256': sha256(apk),
        'installation_executed': False,
        'compatibility': 'Unknown until the installed certificate, package and version are checked. Debug keys may differ between local/CI builds.',
    }
    return metadata, badging, signature


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('apk', type=Path)
    parser.add_argument('--output-directory', type=Path, required=True)
    parser.add_argument('--build-tools', type=Path)
    args = parser.parse_args()
    sdk_root = os.environ.get('ANDROID_HOME') or os.environ.get('ANDROID_SDK_ROOT')
    tools = args.build_tools or (Path(sdk_root) / 'build-tools' / '35.0.0' if sdk_root else None)
    if tools is None:
        parser.error('Set ANDROID_HOME or pass --build-tools')
    apk = args.apk.resolve(strict=True)
    output = args.output_directory.resolve()
    # Copying must not overwrite the build input or anything in its directory.
    if output == apk.parent:
        parser.error('Use a separate output directory')
    root = Path(__file__).resolve().parents[1]
    dirty_source = run('git', '-C', str(root), 'status', '--porcelain', '--untracked-files=all', '--', 'lib', 'android', 'assets', 'pubspec.yaml', 'pubspec.lock').strip()
    if dirty_source:
        raise ValueError('Application source/configuration differs from HEAD; cannot attest APK provenance')
    metadata, badging, signature = inspect(apk, tools)
    metadata.update(
        source_head=run('git', '-C', str(root), 'rev-parse', 'HEAD').strip(),
        source_lib_tree=run('git', '-C', str(root), 'rev-parse', 'HEAD:lib').strip(),
        source_android_tree=run('git', '-C', str(root), 'rev-parse', 'HEAD:android').strip(),
        source_assets_tree=run('git', '-C', str(root), 'rev-parse', 'HEAD:assets').strip(),
        pubspec_sha256=sha256(root / 'pubspec.yaml'),
        lockfile_sha256=sha256(root / 'pubspec.lock'),
        build_mode='debug',
    )
    output.mkdir(parents=True, exist_ok=True)
    target = output / metadata['apk_filename']
    if target.exists() and target.resolve() == apk:
        parser.error('Input and output APK must differ')
    shutil.copy2(apk, target)
    if sha256(target) != metadata['apk_sha256']:
        raise ValueError('Copy checksum mismatch')
    (output / 'apk-metadata.json').write_text(json.dumps(metadata, indent=2) + '\n')
    (output / 'aapt.txt').write_text(badging)
    (output / 'apksigner.txt').write_text(signature)
    (output / 'SHA256SUMS').write_text(f"{metadata['apk_sha256']}  {metadata['apk_filename']}\n")
    print(json.dumps(metadata, indent=2))


if __name__ == '__main__':
    main()
