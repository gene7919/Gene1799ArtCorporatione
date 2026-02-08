
# -*- mode: python ; coding: utf-8 -*-

block_cipher = None

a = Analysis(
    [r'C:\Users\gene1\Desktop\Gene1799ArtCorporatione\gene1799_launcher.py'],
    pathex=[r'C:\Users\gene1\Desktop\Gene1799ArtCorporatione'],
    binaries=[],
    datas=[
        (r'C:\Users\gene1\Desktop\Gene1799ArtCorporatione\logs', 'logs'),
        (r'C:\Users\gene1\Desktop\Gene1799ArtCorporatione\*.md', '.'),
    ],
    hiddenimports=[
        'asyncio',
        'psutil',
        'aiohttp',
    ],
    hookspath=[],
    hooksconfig={},
    runtime_hooks=[],
    excludedimports=[],
    win_no_prefer_redirects=False,
    win_private_assemblies=False,
    cipher=block_cipher,
    noarchive=False,
)

pyz = PYZ(a.pure, a.zipped_data, cipher=block_cipher)

exe = EXE(
    pyz,
    a.scripts,
    a.binaries,
    a.zipfiles,
    a.datas,
    [],
    name='Gene1799_Enhanced',
    debug=False,
    bootloader_ignore_signals=False,
    strip=False,
    upx=True,
    upx_exclude=[],
    runtime_tmpdir=None,
    console=True,
    disable_windowed_traceback=False,
    target_arch=None,
    codesign_identity=None,
    entitlements_file=None,
    icon=None,
)

coll = COLLECT(
    exe,
    a.binaries,
    a.zipfiles,
    a.datas,
    strip=False,
    upx=True,
    upx_exclude=[],
    name='Gene1799_Enhanced',
)
