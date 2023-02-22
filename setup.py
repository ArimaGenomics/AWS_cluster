from setuptools import setup
import sys

if sys.version_info < (3, 6):
    sys.exit('Sorry, Python < 3.6 is not supported')

# todo: requirements
setup(
    name='arimapy',
    version='0.1',
    author='Fulcrum Genomics',
    author_email='no-reply@fulcrumgenomics.com',
    maintainer='Fulcrum Genomics',
    maintainer_email='no-reply@fulcrumgenomics.com',
    description='Python/Snakemake Skeleton',
    url='https://github.com/fulcrumgenomics/python-snakemake-skeleton',
    packages=['arimapy'],
    package_dir={'': 'src/python'},
    entry_points={
        'console_scripts': ['arima-tools=arimapy.tools.__main__:main']
    },
    include_package_data=True,
    zip_safe=False,
    classifiers=[
        'Environment :: Console',
        "Programming Language :: Python :: 3",
        "Development Status :: 3 - Alpha",
        "Intended Audience :: Developers",
    ]
)
