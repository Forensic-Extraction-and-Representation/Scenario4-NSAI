import hashlib

import pandas as pd
import sys
import re

def parse_bodyfile(bodyfile_path):
    columns = ['MD5', 'name', 'inode', 'mode_as_string', 'UID', 'GID', 'size', 'atime', 'mtime', 'ctime', 'crtime']
    data = []

    with open(bodyfile_path, 'r') as file:
        for line in file:
            if line.startswith('#') or not line.strip():
                continue
            parts = re.split(r'\|', line.strip(), maxsplit=10)
            if len(parts) == 11:
                # Convert timestamps to integers
                for i in range(7, 11):
                    parts[i] = int(parts[i]) if parts[i].isdigit() else 0
                
                # Convert size to integer
                parts[6] = int(parts[6]) if parts[6].isdigit() else 0

                # Replace "/" with "\" for Windows paths
                parts[1] = parts[1].replace('/', '\\')
                data.append(parts)

    df = pd.DataFrame(data, columns=columns)
    return df

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: python parse_bodyfile.py <bodyfile_path> <output_json>")
        sys.exit(1)

    # hash the input file to use as the HostSha1 value

    bodyfile_path = sys.argv[1]
    output_json = sys.argv[2]

    with open(bodyfile_path, 'rb') as f:
        host_sha1 = hashlib.sha1(f.read()).hexdigest()

    df = parse_bodyfile(bodyfile_path)
    
    # Populate static column values
    df['HostSha1'] = host_sha1
    df['TypeName'] = 'TSK_METADATA'
    df['Category'] = 'Metadata'
 
    # Rename columns to match the Autopsy Ontology
    df.rename(columns={
        'name': 'SourceFile',
        'MD5': 'SourceFileMd5',
        'mtime': 'ModifiedDateTime',
        'crtime': 'CreatedDateTime'
    }, inplace=True)

    # Output to JSON objects per-record
    df[['TypeName', 'Category', 'HostSha1', 'SourceFile', 'SourceFileMd5', 'ModifiedDateTime', 'CreatedDateTime']].to_json(output_json, orient='records')
    print(f"Parsed data saved to {output_json}")