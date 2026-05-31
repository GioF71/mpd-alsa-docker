#!/usr/bin/env python3
import argparse
import sys

try:
    from mpd import MPDClient, CommandError
except ImportError:
    print("Error: The 'python-mpd2' library is required.", file=sys.stderr)
    print("Install it using: pip install python-mpd2", file=sys.stderr)
    sys.exit(1)

def ensure_partition_and_route_output(host, port, target_partition, target_output):
    client = MPDClient()
    try:
        print(f"Connecting to MPD daemon at {host}:{port}...")
        client.connect(host, port)
        
        # 1. Fetch current active partitions (Fixed method name here)
        partitions_raw = client.listpartitions()
        existing_partitions = set()
        for p in partitions_raw:
            if isinstance(p, dict) and "partition" in p:
                existing_partitions.add(p["partition"])
            elif isinstance(p, str):
                existing_partitions.add(p)

        # 2. Ensure target partition exists
        if target_partition not in existing_partitions:
            print(f"Partition '{target_partition}' does not exist. Creating it...")
            client.newpartition(target_partition)
        else:
            print(f"Partition '{target_partition}' already exists.")

        # 3. Switch client context focus to the target partition
        client.partition(target_partition)

        # 4. Move the output into this partition
        print(f"Routing output '{target_output}' to partition '{target_partition}'...")
        client.moveoutput(target_output)
        print("Success: Configuration applied successfully.")
    except CommandError as ce:
        print(f"MPD Protocol Error: {ce}", file=sys.stderr)
        sys.exit(2)
    except Exception as e:
        print(f"Network/Unexpected Error: {e}", file=sys.stderr)
        sys.exit(3)
    finally:
        try:
            client.disconnect()
        except:
            pass

def main():
    parser = argparse.ArgumentParser(
        description="Runtime automation tool to provision MPD partitions and route audio outputs."
    )
    parser.add_argument("--host", default="127.0.0.1", help="MPD server address (default: 127.0.0.1)")
    parser.add_argument("--port", type=int, default=6600, help="MPD server port (default: 6605)")
    parser.add_argument("partition", help="Name of the partition to verify/create (e.g., 'oh')")
    parser.add_argument("output", help="Name or ID of the audio output to route (e.g., 'Out1: DAC')")

    args = parser.parse_args()
    ensure_partition_and_route_output(args.host, args.port, args.partition, args.output)

if __name__ == "__main__":
    main()