
import unittest
from unittest.mock import patch
from datetime import datetime, timedelta, timezone

from pathlib import Path
import sys

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "lambda"))

from backup import lambda_handler


class TestBackup(unittest.TestCase):

    @patch("backup.boto3.client")
    def test_creates_and_deletes_snapshots(self, mock_client):
        ec2 = mock_client.return_value

        ec2.describe_volumes.return_value = {
            "Volumes": [{"VolumeId": "vol-123"}]
        }

        ec2.create_snapshot.return_value = {
            "SnapshotId": "snap-new"
        }

        ec2.describe_snapshots.return_value = {
            "Snapshots": [{
                "SnapshotId": "snap-old",
                "StartTime": (
                    datetime.now(timezone.utc) - timedelta(days=8)
                )
            }]
        }

        lambda_handler({}, None)

        ec2.create_snapshot.assert_called_once()
        ec2.create_tags.assert_called_once()
        ec2.delete_snapshot.assert_called_once_with(
            SnapshotId="snap-old"
        )

    @patch("backup.boto3.client")
    def test_handles_no_volumes(self, mock_client):
        ec2 = mock_client.return_value
        ec2.describe_volumes.return_value = {"Volumes": []}
        ec2.describe_snapshots.return_value = {"Snapshots": []}

        lambda_handler({}, None)

        ec2.create_snapshot.assert_not_called()
        ec2.delete_snapshot.assert_not_called()


if __name__ == "__main__":
    unittest.main()

