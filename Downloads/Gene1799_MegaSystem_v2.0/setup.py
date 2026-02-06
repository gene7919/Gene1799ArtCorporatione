"""
Gene1799 Core - Setup Package

Gene1799 Art Corporation
Fondatori: Marco Antonio Saverio Mazzitelli & Fabio Amedeo Lo Presti (Arthemis Ludovici)
License: 16/L4090879L
"""

from setuptools import setup, find_packages

setup(
    name='gene1799_core',
    version='2.0.0',
    author='Gene1799 Art Corporation',
    author_email='info@gene1799.art',
    description='Gene1799 MegaSystem - AI Platform with Digital Signature',
    long_description=open('README.md', encoding='utf-8').read() if __import__('os').path.exists('README.md') else '',
    long_description_content_type='text/markdown',
    url='https://github.com/gene1799/megasystem',
    packages=find_packages(),
    classifiers=[
        'Development Status :: 4 - Beta',
        'Intended Audience :: Developers',
        'License :: Other/Proprietary License',
        'Operating System :: OS Independent',
        'Programming Language :: Python :: 3',
        'Programming Language :: Python :: 3.8',
        'Programming Language :: Python :: 3.9',
        'Programming Language :: Python :: 3.10',
        'Programming Language :: Python :: 3.11',
        'Programming Language :: Python :: 3.12',
        'Topic :: Software Development :: Libraries :: Python Modules',
        'Topic :: Security :: Cryptography',
    ],
    python_requires='>=3.8',
    install_requires=[],
    extras_require={
        'dev': [
            'pytest>=7.0.0',
            'black>=22.0.0',
            'mypy>=1.0.0',
        ],
    },
    entry_points={
        'console_scripts': [
            'gene1799-sign=gene1799_core.signing:main',
        ],
    },
    project_urls={
        'Documentation': 'https://docs.gene1799.art',
        'Source': 'https://github.com/gene1799/megasystem',
    },
    license='16/L4090879L',
    keywords='gene1799 digital-signature nft blockchain ai agents',
)
