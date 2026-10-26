
from datetime import datetime, timedelta, timezone

import boto3


RETENTION_DAYS = 7


def lambda_handler(event, context):
    ec2 = boto3.client("ec2")
    now = datetime.now(timezone.utc)
    cutoff = now - timedelta(days=RETENTION_DAYS)

    # Find volumes marked for backup.
    response = ec2.describe_volumes(
        Filters=[
            {"Name": "tag:Backup", "Values": ["true"]}
        ]
    )

    # Create a snapshot for each matching volume.
    for volume in response["Volumes"]:
        snapshot = ec2.create_snapshot(
            VolumeId=volume["VolumeId"],
            Description="Automated Sprint 8 backup"
        )

        ec2.create_tags(
            Resources=[snapshot["SnapshotId"]],
            Tags=[
                {"Key": "ManagedBy", "Value": "sprint-8"},
                {
                    "Key": "CreationTimestamp",
                    "Value": now.isoformat()
                }
            ]
        )

        print("Created snapshot:", snapshot["SnapshotId"])

    # Find snapshots created by this backup system.
    response = ec2.describe_snapshots(
        OwnerIds=["self"],
        Filters=[
            {"Name": "tag:ManagedBy", "Values": ["sprint-8"]}
        ]
    )

    # Delete snapshots older than seven days.
    for snapshot in response["Snapshots"]:
        if snapshot["StartTime"] < cutoff:
            ec2.delete_snapshot(
                SnapshotId=snapshot["SnapshotId"]
            )
            print("Deleted expired snapshot:", snapshot["SnapshotId"])

    print("Backup job completed.")

