import tempfile
from pathlib import Path
import unittest
from unittest.mock import patch
from inspect_android_apk import inspect

BADGING = "package: name='mz.lifeos.lifeos' versionCode='12' versionName='0.9.2'\nsdkVersion:'24'\ntargetSdkVersion:'36'\napplication-debuggable\nlaunchable-activity: name='mz.tudoaki.tudo_aki.MainActivity'\nnative-code: 'arm64-v8a' 'x86_64'\n"
CERT = 'Signer #1 certificate SHA-256 digest: ' + 'a' * 64 + '\n'

class ApkInspectionTest(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.apk = Path(self.tmp.name) / 'input.apk'
        self.apk.write_bytes(b'synthetic tool fixture, not an APK')

    def evaluate(self, badging=BADGING, certificate=CERT):
        with patch('inspect_android_apk.run', side_effect=[badging, certificate]):
            return inspect(self.apk, Path('/test-tools'))[0]

    def test_verified_debug_metadata_does_not_claim_installation(self):
        value = self.evaluate()
        self.assertEqual(value['application_id'], 'mz.lifeos.lifeos')
        self.assertEqual(value['min_sdk'], 24)
        self.assertEqual(value['version_code'], 12)
        self.assertFalse(value['installation_executed'])
        self.assertEqual(value['signer_certificate_sha256'], 'a' * 64)

    def test_release_is_rejected(self):
        with self.assertRaisesRegex(ValueError, 'not debuggable'):
            self.evaluate(badging=BADGING.replace('application-debuggable\n', ''))

    def test_changed_identifier_is_rejected(self):
        with self.assertRaisesRegex(ValueError, 'application ID'):
            self.evaluate(badging=BADGING.replace('mz.lifeos.lifeos', 'example.other'))

    def test_ambiguous_certificate_is_rejected(self):
        with self.assertRaisesRegex(ValueError, 'exactly one'):
            self.evaluate(certificate=CERT + CERT.replace('#1', '#2'))

if __name__ == '__main__':
    unittest.main()
