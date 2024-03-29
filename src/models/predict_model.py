# -*- coding: utf-8 -*-
import click
import logging
from pathlib import Path
from os.path import join
from dotenv import find_dotenv, load_dotenv

from sklearn.metrics import accuracy_score
from sklearn.metrics import confusion_matrix
from sklearn.metrics import classification_report

from src.utilities.utilities import load_pickle


@click.command()
@click.argument('data_filepath', type=click.Path())
@click.argument('model_filepath', type=click.Path())
def main(data_filepath, model_filepath):
    """ predicts model
    """
    logger = logging.getLogger(__name__)
    logger.info('predicting with model')

    # # Creating features
    LRmodel = load_pickle(join(model_filepath, "LRmodel.pkl"))
    X_validation = load_pickle(join(data_filepath, "X_validation.pkl"))
    Y_validation = load_pickle(join(data_filepath, "Y_validation.pkl"))

    predictions = LRmodel.predict(X_validation)
    logging.info(accuracy_score(Y_validation, predictions))
    logging.info(confusion_matrix(Y_validation, predictions))
    logging.info(classification_report(Y_validation, predictions))


if __name__ == '__main__':
    log_fmt = '%(asctime)s - %(name)s - %(levelname)s - %(message)s'
    logging.basicConfig(level=logging.INFO, format=log_fmt)

    # not used in this stub but often useful for finding various files
    project_dir = Path(__file__).resolve().parents[2]

    # find .env automagically by walking up directories until it's found, then
    # load up the .env entries as environment variables
    load_dotenv(find_dotenv())

    main()
