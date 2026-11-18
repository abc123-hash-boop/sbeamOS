import unittest

from sbeamos_installer.disks import _mountpoints


class MountpointTests(unittest.TestCase):
    def test_collects_nested_mountpoints(self):
        tree = {
            "mountpoints": ["/"],
            "children": [
                {"mountpoints": ["/boot"], "children": [
                    {"mountpoint": "/boot/efi"}
                ]}
            ],
        }
        self.assertEqual(_mountpoints(tree), ["/", "/boot", "/boot/efi"])

    def test_ignores_empty_mountpoints(self):
        self.assertEqual(_mountpoints({"mountpoints": [None], "children": []}), [])


if __name__ == "__main__":
    unittest.main()
