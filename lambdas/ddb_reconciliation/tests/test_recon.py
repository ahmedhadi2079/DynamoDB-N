import os
import sys

sys.path.append(os.path.abspath("../"))
from lambda_function import recon_check_counts


def test_recon_counts_diffs_small():
    """
    Due to timing of running the recon and getting the latest scanned count
    from Dynamo we usually get incosistencies of 1 or 2 in our compared counts
    between Athena and Dynamo, therefore if that happens it shouldn't
    throw an error.
    """

    dynamo_count = 15000
    athena_count = 14998
    threshold = 0.9995
    result = recon_check_counts(dynamo_count, athena_count, threshold)

    assert result


def test_recon_counts_diffs_big():
    """
    Due to timing of running the recon and getting the latest scanned count
    from Dynamo we usually get incosistencies of 1 or 2 in our compared counts
    between Athena and Dynamo, therefore if that happens it shouldn't
    throw an error.
    """

    dynamo_count = 15000
    athena_count = 14988
    threshold = 0.9995
    result = recon_check_counts(dynamo_count, athena_count, threshold)

    assert not result
