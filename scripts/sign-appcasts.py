#!/usr/bin/env python3
"""Generate signed, architecture-specific feeds. Never print or persist private keys."""
from pathlib import Path
import os, subprocess, tempfile, shutil
root = Path(__file__).resolve().parents[1]
version = (root/'VERSION').read_text().strip()
tool = root/'.build/sparkle/bin/generate_appcast'
key = os.environ.get('SPARKLE_PRIVATE_KEY')
for arch in ('arm64','x86_64'):
    with tempfile.TemporaryDirectory(prefix='string-notes-feed-') as work:
        folder=Path(work)
        name=f'StringNotes-{version}-{arch}'
        shutil.copy2(root/'dist'/f'{name}.zip', folder/f'{name}.zip')
        # Plain text avoids remotely loading release notes into the update prompt.
        shutil.copy2(root/'release-notes'/f'v{version}.md', folder/f'{name}.txt')
        command=[str(tool),'--maximum-deltas','0','--embed-release-notes',
                 '--download-url-prefix',f'https://github.com/TD21forever/string-notes/releases/download/v{version}/',
                 '-o',str(root/'dist'/f'appcast-{arch}.xml')]
        command += ['--ed-key-file','-'] if key else ['--account','local.stringnotes.app']
        subprocess.run(command+[str(folder)],input=(key+'\n').encode() if key else None,check=True)
