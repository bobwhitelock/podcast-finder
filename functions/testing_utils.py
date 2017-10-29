
import os
import yaml


def load_environment():
    stage = 'dev'
    with open('secrets.yml') as f:
        secrets = yaml.load(f)[stage].items()

    for var, value in secrets:
        os.environ[var] = value
