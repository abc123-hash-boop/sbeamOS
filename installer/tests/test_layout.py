import unittest

from sbeamos_installer.engine import _partition_names


class PartitionNameTests(unittest.TestCase):
    def test_nvme(self):
        self.assertEqual(_partition_names("/dev/nvme0n1"),
                         ("/dev/nvme0n1p1", "/dev/nvme0n1p2", "/dev/nvme0n1p3"))

    def test_sata(self):
        self.assertEqual(_partition_names("/dev/sda"),
                         ("/dev/sda1", "/dev/sda2", "/dev/sda3"))

    def test_mmc(self):
        self.assertEqual(_partition_names("/dev/mmcblk0"),
                         ("/dev/mmcblk0p1", "/dev/mmcblk0p2", "/dev/mmcblk0p3"))


if __name__ == "__main__":
    unittest.main()
