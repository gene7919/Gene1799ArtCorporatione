from setuptools import setup, find_packages

setup(
    name="suitev17",
    version="10.0.0",
    packages=find_packages(),
    install_requires=["requests","tk","chromadb"],
    entry_points={"console_scripts":["suitev17=AI_Engine.launcher:main"]}
)
